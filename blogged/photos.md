# Storing Photos for the Long Term

You have photos on your computer. You would probably be really sad if you lost
them. Let's discuss some strategies for ensuring that doesn't happen.

## What you are doing now is probably not enough.

You current strategy is to have photos and critical files stored on your most
current laptop and maybe some things in Dropbox. This means you will probably
lose your data sometime in the next three years.

Hard drives fail, often, and are unrecoverable, or expensive to recover.

The software that manages your photos is written by people who are bad at their
jobs, or didn't anticipate the software running on (insert hardware/software
condition 10 years from now here) and it breaks, destroying your photos in the
process.

[Backup][dropbox] [services][crashplan] fail, often enough to make you worry.
Apple can't be trusted to reliably deliver messages with iMessage, I don't
trust Time Machine *at all*.

Apartments and cars get broken into and laptops/external drives are good
candidates for theft. You can buy renters insurance, but you can't get your
photos back.

## What you should do

I'm going to focus specifically on keeping photos for a long time. For files
and folders which change more often, I use git and source code tools like
Github or Bitbucket. For work environments that take a while to set up, I try
to automate installation with shell scripts instead of trying to store the
entire environment via Time Machine or similar.

I'm also going to pick a thirty year time horizon, just for fun. If you want
something to last for thirty years, you can't just store it on your local
machine because your hard drive will probably fail between now and then, and
then you lose your photos. So you want to store it on your machine and then
also somewhere offsite (e.g. not in the same 5-mile radius as your machine).

### Storage Tool

Which raises the question, which storage/backup companies will be around in 30
years? Any small enough candidate, even Dropbox, could get acquired or shut
down in that time frame. My guess right now is that Amazon Web Services will be
around the longest, because it is profitable, already part of a large, growing
company, and the service is growing rapidly.

Specifically, I am putting a bet on [Amazon Glacier][glacier], which has
extremely low storage costs - $0.01 per GB - and is one of the most reliable
services Amazon runs. Glacier is a subset of Simple Storage Service (S3)
which has had extraordinarily good availability in the 7-8 years it's been
available. In addition Amazon regularly publishes information on the technology
underpinning S3, see "Amazon Dynamo paper" for example.

 [glacier]: https://aws.amazon.com/glacier/

I use [Arq][arq] to back up photos to Glacier. It seems fairly stable, has
software preferences for the right things, and I am encouraged that the author
charges for the software, which means he/she has an incentive to continue
developing the product and making sure that it works. This is $30 but this is
still much, much cheaper than any other tool (iCloud for example would be $100
per year).

I have 52 GB of files, which means I'll pay roughly $7 per year to have 11
years of photos stored safely in the cloud. Not bad.

I would consider [Tarsnap][tarsnap] as well, which encrypts your data, but it's
currently 2.5x the price of Glacier. I expect this price to decline soon.

 [tarsnap]: https://www.tarsnap.com/

### Photo Management Software

The second piece is you need to choose a stable piece of software for viewing
and managing your photos. This is orders of magnitude more risky than Glacier.
The ideal piece of software would have:

- An easy to understand file format, published online

- Source code available online

- Some support for grouping photos into albums and importing them from my
  phone/camera/whatever

- Some sort of tool for auto-adjusting the layers on a photo, cropping it,
  editing the brightness/contrast. Not Lightroom, but enough to make a photo
  better than it was.

- Supports hundreds of gigabytes of photos without falling over.

I haven't done as much research into this as with backup solutions, but there
are a few tools. Picasa is supported by Google and relies on Google's charity
to stay running and supported. Lightroom is very nice, but overshoots my needs,
is very expensive, and Adobe may run out of money and fold within the next
30 years. This leaves iPhoto, which isn't well documented, or open source,
but mostly works, some of the time, can crop/edit photos while saving the
originals, and is a core component of Apple's Mac product, which may also die,
when we all have tablets. At least iPhoto stores the files on disk.

If I was a better person, I'd manually arrange photos in files on my
filesystem and use that. But I am not.

## Problems

In this game it's a question of how paranoid you want to be, and how much
your photos are worth to you. If they're worth a lot it's worth investing
significant time and resources into redundant backup systems. Specifically, the
3-2-1 rule suggests storing backups in 3 different places, 2 different file
systems (or photo management tools), with at least one offsite. For photos,
backing up to CD's or tapes is not a terrible option though it's not very
efficient and CD's also die. Using a 2nd photo management software solution,
storing the data for that one on an external drive, and backing one of them up
to Glacier every night is not a terrible idea.

My photos are worth a lot to me, but I'm not going to go insanely overboard;
if my hard drive dies, and Glacier loses my data, that would suck, but I'm
willing to gamble on the one-in-a-million odds of them not both happening
simultaneously.

I am most worried about the management software; recently iPhoto decided I had
no photos in my library and deleted all of the metadata for those photos
(albums, rotation information, etc), leaving only the raw copies in my library.
This was very sad, though I didn't lose the photos themselves, and might be
able to recover the metadata if I am lucky. So yeah, I am not too happy with
this. I now store important iPhoto databases in git, backed up to Bitbucket, so
I can pull them back down in the event of another catastrophic failure.

## Conclusion

This is too long already. Ensuring your photos aren't lost is difficult, and
probably requires professional experience as a computer programmer to get
right, or for you to part with a significant amount of money, or achieve a
large amount of good luck, to avoid the bad things that happen to most people
who just hope their photos stick around. I wish you the best of luck.

 [crashplan]: http://jeffreydonenfeld.com/blog/2011/12/crashplan-online-backup-lost-my-entire-backup-archive/
 [dropbox]: http://www.businessinsider.com/professor-suffers-dropbox-nightmare-2013-9
 [arq]: http://www.haystacksoftware.com/arq/
