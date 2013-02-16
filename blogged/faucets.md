# A quick design exploration featuring shower handles

How should you design the controls for a shower? Let's take a quick look.

### Affordance

<img src="/wp-content/uploads/2013/02/Claw-hammer.jpg" alt="a hammer" />

A device should make clear by its design how to use it. Take a hammer for
example.

No one has ever looked at a hammer and wondered which end you are supposed to
grab and which part you're supposed to pound nails with. This is an example of
good affordance.

Some things do not have such good affordance, like the shower at my friend's
house. It looked like this, except the handles were perfectly horizontal.

<img src="/wp-content/uploads/2013/02/shower-handles.jpg" alt="shower faucet and handles" class="inline" />

The shower handles have one good affordance - you know where you are supposed
to grab, and it's clear you are supposed to rotate the handles. However they
leave the following questions unanswered.

- Which one is hot and which one is cold?
- How far do I have to turn the handles to reach the desired temperature?
- What combination of hot and cold do I want?
- Which direction do I turn the handles, up or down?

That's pretty bad for a device which doesn't need to do much. Maybe not as bad
as this sink with two faucets, one for hot and one for cold:

<img class="inline" src="/wp-content/uploads/2013/02/Vw3A9.jpg" alt="sink fail" />

But it leaves a lot for the user to figure out, especially when there
is usually a lag between when you move the handle and when the temperature
changes, making it tough to figure out what's going on.

### Designing a Better Showerhead

Functionally, a device should have two properties: 

1. Allow you to do the tasks you want
2. Make it easy for you to do those tasks.

That's it - if the device is pretty on top of this, that's a big bonus. What do
we want a shower to do?

* Turn on hot water
* Occasionally, make it even hotter
* Turn off the water

That's it. These tasks don't map terribly well to the current set of faucets,
which ask you to perform a juggling act to get water at the right temperature.

So how can we design a tool to do just this? I'll assume for the moment we have
to stick with a physical interface - a tablet for a shower control would allow
interesting choices like customizing the shower temperature per user, but would
put this out of the reach of most homes. A good start would be a simple control
to turn the water on and off. It's not necessary that the control shows the
state of water, on or off, as you get that feedback from the hot water - it
could just be a button that you press.

That's a good start, now how to control the temperature? I wasn't able to find
good data, but my guess is that most people want showers in a 15 degree range
of hot to very hot. Either way, there should be a sliding control that lets you
select temperatures in this range.

The sliding shower handle comes close and this is one of the better designs
I've seen:

<img class="inline" src="/wp-content/uploads/2013/02/peerless_faucet.jpg" alt="Sliding shower handle" />

However it still has two problems. It shouldn't have a cold range at all, or
select a temperature which will burn you.

Second, sliding the handle changes both pressure and temperature. You should
get the best pressure available the moment you slide the handle a little bit.

Third, the feedback you get when you turn the shower off could be better. The
device could offer a little resistance, and then slide into place when turning
it on or off - this way you *know* that the shower is on or off, similar to the
way stoves and iPhone headphones slide into place with a satisfying *click*.

A shower handle that gave resistance when turning it on or off, turned on full
blast straight away, and only let you slide between various hot temperatures.
That would be nice.

