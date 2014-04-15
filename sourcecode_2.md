# Source Code Stolen from Github.com

The open source community was shocked to learn Tuesday that millions of lines
of source code had gone missing from Github.com, a popular online version
control website.

Github stores source code in "reposotories", which are big chunks of code that
can be edited by Github members. Most version control websites will keep a
small portion of the source code online (collectively known as the "hot repos")
and store the rest of the repos offline, to prevent a mass download of all of
the source code. Instead of using hot repos and cold repos, Github stored all
of the source code online, which allowed the attackers to download all of it.

It's unclear how long the source code has been missing. Slides from a leaked
Keynote deck indicated that Github's main strategy was to "just kinda ask
people to push their code back up to the site without noticing anything". On
Twitter, some people attributed the theft to an honest mistake (Github left
the popular port 22 open for the attackers), while others speculated that the
founders absconded with the code after building up trust in Github.

Github is based on a "distributed version control" system, designed so that
many different copies of the source code can live on different computers. But
because everyone stores their source code in Github, it became very easy for
the attackers to download all of the source code from one place.

"My code could be running on anyone's computer right now, anywhere in
the world," said open source developer Andrew Benton. "Frankly, that is
terrifying." Other members of the community laughed at anyone who thought their
source code was secure when hosted with a version control system that runs in
the cloud.

Github could not be reached for comment, but they did release a special
"Hackedocat" to commemorate the occasion.

<a href="https://kev.inburke.com/wp-content/uploads/2014/04/hackedocat.png"><img src="https://kev.inburke.com/wp-content/uploads/2014/04/hackedocat-300x300.png" alt="Hackedocat!" width="300" height="300" class="alignnone size-medium wp-image-3132" /></a>

At press time, the top comments on Hacker News were from a person complaining
about how dumb Github is for losing the code, another person explaining to
everyone that this article is satire, and a third person explaining that while
he understands this is satire, the article is "dumb" and "not that funny", and
seven non-sequiturs about the wisdom of free markets.

*with thanks to Kyle Conroy, Andrew Benton, and Gabriel Gironda for reading
drafts, and to Kyle for the Hackedocat*
