# Genetically Creating Roller Coaster Tycoon Roller Coasters

I used to play a ton of Roller Coaster Tycoon when I was a kid. I loved the
game but I was never very good at making the roller coasters. They always felt
too spread out, or too unnatural looking. As a ten year old I idly wondered
about writing a computer program that was really good at playing the game. What
sort of parks would it make? How would a computer approach the freedoms
inherent in an empty park? What would we learn about the game engine from doing
so?

<img src="/static/rawblog/coolcoaster.jpg" alt="A cool coaster" />

In case you're not familiar, Roller Coaster Tycoon is a amusement park
simulation game most notable because the entire game was written in x86
assembler by Chris Sawyer.

Finally a few months ago, I had the tools and the free time available to
work on this. I made some progress toward writing a program that would generate
cool looking roller coasters. Let's examine the steps in turn.

### Interacting with the Game

So cool, you have a program that can generate roller coasters. How do you
actually put them in the game, or integrate them into your parks?

Fortunately, Roller Coaster Tycoon has a format for saving track layouts
to disk. Even more amazingly, this format has been documented. To compress
space (it seems a little quaint today), RCT used a cheap run-length encoding
algorithm that would compress duplicates of the same byte. Once you decode the
ride data, it follows a format. Byte 0 stores the ride type - 00000010 is a
suspended steel roller coaster, for example. Some bytes indicate the presence
of flags - the 17th bit tells you whether the coaster can have a vertical loop.
And so on, and so on.

So great! I could write my coaster generator in any language I wanted, write
out the file to disk, then load it from any of the parks.

### Getting Track Data

There are a lot of track pieces in the game, and I needed to get a lot of
data about each of them to be able to make assertions about generated roller
coasters. As an example, if the track is currently banked left, which pieces
are even possible to construct next?

A steep upward slope track piece increases the car height 4 units. A sharp
left turn would advance the car 3 squares forward and 3 squares left, and also
rotate the car's direction by 90 degrees. I had less than zero interest in
coding all of this information by hand, and would probably make a mistake doing
it. So I went looking for the source of truth in the game..

#### OpenRCT2

Literally the same *week* that I started looking at this, Ted John started an
open source project to decompile the Roller Coaster Tycoon 2 source from x86
into C. More importantly (for me), Ted and the source code actually showed how
to read and decompile the source of the game.

The repository shipped with an EXE that would load the C sources before the x86
code. From there, the C code could (and did, often) use assembler calls to jump
back into the game source, for parts that hadn't been decompiled yet.

This also introduced me to the tools you use to decompile x86 into C. We
used the reverse engineering tool IDA Pro to read the raw assembly, with a
shared database that had information on subroutines that had been decompiled.
Using IDA is probably as close as I will come to a profession in code-breaking
and/or reverse engineering.

Most of the time with IDA involved reading, annotating the code, and then
double checking your results against other parts of the code, the same way
you might annotate a crossword puzzle. Other times I used guess and check -
change a value in the code, then re-run the game and see what specifically had
changed, or use debugging statements to see what went on.

So I started looking for the track data in the game. This turned out to be
really, really difficult. You would have a hunch, or use the limited search
capability in the game to search for something you thought should be there.
Ultimately I ended up determining where the strings "Too high!" and "Too low!"
were stored in the game, figuring that track height data would have been
computed near there.

It turns out that track data is not stored in one big map but in several maps
all around the code base - some places store information about banks, some
store information about heights and it's tricky to compile it all together.
Ultimately, I was able to figure it out by spending enough time with the code
and testing different addresses to see if the values there lined up with the
pre-determined track order.

### Visualizing rides

With a genetic algorithm you are going to be generating a lot of roller
coasters. I wanted a quick way to see whether those roller coasters were
getting better or not by plotting them. So I used the image/2d package to draw
roller coasters. To start I didn't try for an isometric view, although that
would be fun to draw. Instead I just plotted height change in one image and x/y
changes in another image. Running this against existing roller coasters also
revealed some flaws in my track data.

### A fitness function

A good fitness function will have penalties/rewards for various pieces of
behavior.

- Is the ride complete?

- Does the ride intersect itself at any points?

- Does the ride respect gravity, e.g. will a car make it all the way around the
  track?

- How exciting is the ride, per the in-game excitement meter?

- How nauseating is the ride, per the in-game excitement meter?

The first two points on that list are easy; the last three are much more
difficult. Finding the excitement data was very tricky. I eventually found it
by getting the excitement for a "static" ride with no moving parts (the Crooked
House) and searching for the actual numbers used in the game. Here's the
function that computes excitement, nausea and intensity for a Crooked House
ride.

[bash]
sub_65C4D4 proc near
or      dword ptr [edi+1D0h], 2
or      dword ptr [edi+1D0h], 8
mov     byte ptr [edi+198h], 5
call    sub_655FD6
mov     ebx, 0D7h ; ''
mov     ecx, 3Eh ; '>'
mov     ebp, 22h ; '"'
call    sub_65E7A3
call    sub_65E7FB
mov     [edi+140h], bx
mov     [edi+142h], cx
mov     [edi+144h], bp
xor     ecx, ecx
call    sub_65E621
mov     dl, 7
shl     dl, 5
and     byte ptr [edi+114h], 1Fh
or      [edi+114h], dl
retn
sub_65C4D4 endp
[/bash]

Got that? In this case 0xD7 is 215, which is the ride's excitement rating. This
is then stored in the ride's location in memory (register `edi`), at the offset
`0x140`. In between there are a few subroutine calls, which shows that nothing
is ever really easy when you are reading x86, as well as calls to functions
that I have nothing besides hunches about.

Anyway, when you turn this into C, you get something like this:

[c]
void crooked_house_excitement(rct_ride *ride)
{
	// Set lifecycle bits
	ride->lifecycle_flags |= RIDE_LIFECYCLE_TESTED;
	ride->lifecycle_flags |= RIDE_LIFECYCLE_NO_RAW_STATS;
	ride->var_198 = 5;
	sub_655FD6(ride);

	ride_rating excitement	= RIDE_RATING(2,15);
	ride_rating intensity	= RIDE_RATING(0,62);
	ride_rating nausea		= RIDE_RATING(0,34);

	excitement = apply_intensity_penalty(excitement, intensity);
	rating_tuple tup = per_ride_rating_adjustments(ride, excitement, intensity, nausea);

	ride->excitement = tup.excitement;
	ride->intensity = tup.intensity;
	ride->nausea = tup.nausea;

	ride->upkeep_cost = compute_upkeep(ride);
	// Upkeep flag? or a dirtiness flag
	ride->var_14D |= 2;

	// clear all bits except lowest 5
	ride->var_114 &= 0x1f;
	// set 6th,7th,8th bits
	ride->var_114 |= 0xE0;
}
[/c]

And we're lucky in this case that the function is relatively contained; many
places in the code feature jumps and constructs that make following the code
pretty tricky.

So this one wasn't too bad, but I got bogged down trying to compute excitement
for a ride that had a track. The function gets orders of magnitude more complex
than this. One positive is, as far as I can tell, excitement and nausea ratings
are wholly functions of overall ride statistics like the vertical and lateral
G-forces, and there's no accumulator per track segment.

Most of the computation involves multiplying a ride statistic by a constant,
then bit shifting the value so it can't be too high/influence the final number
by too much.

And sadly this is where the project stalled. It was impossible to test the C
code, because the track computation functions were buried four subroutines
deep, and each of those subroutines had at least 500 lines of code. Decompiling
each of these correctly, just to get to the code I wanted, was going to be
a massive pain. There are ways around this, but ultimately I got back from
vacation and had to focus on more pressing issues, like trying not to run out
of money.

### Conclusion

You can hack Roller Coaster Tycoon! There are a bunch of people doing
interesting stuff with the game, including improving the peep UI, working
on cross compilation (you can play it on Macs!), adding intrigues like the
possibility of a worker strike, removing limitations based on the number of
bytes (you can only have 255 rides, for example), and more.

It's been really fun having an utterly useless side project. I learned a lot
about registers, calling conventions, bit shifting tricks, and other things
that probably won't be useful at all, for anything.

I will definitely revisit this project at some point, hopefully when more of
the game has been decompiled, or I might try to dig back into the x86/C more on
my own.

