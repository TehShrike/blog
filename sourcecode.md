# Source Code Stolen from Github.com

The open source community was shocked to learn Friday that hundreds of
thousands of lines of source code had been stolen from Github.com, a popular
online version control website. Security experts were left scratching their
heads at how easily the attackers gained access to download all of the source
code, valued at tens of millions of dollars. It was unclear what the motive
was, though some suggested the attackers may want to sell the source code to
foreign governments.

The attackers used a common program called "ssh" to download all of the files.
Shockingly, Github left port 22, a commonly-used port for SSH connections, open
for the attackers to download the source code. It is possible that Github was
operating for months or even years in this vulnerable state.

Github stores source code in "reposotories", which are big chunks of code that
can be edited by Github members. Most version control websites will keep a
small portion of the source code online (collectively known as the "hot repos")
and store the rest of repos offline, to prevent a mass download of all of the
source code. Github did not follow that practice, which allowed the attackers
to download most of the code.

Github is based around a program called "git", which is a "distributed version
control" system. Git is designed so that many different copies of the source
code can live on different computers. Since everyone stores their source code
in Github though, this made it very easy for the attackers to download all of
the source code from one place.

"My code could be running on anyone's computer right now, anywhere in
the world, " said open source developer Andrew Benton. "Frankly, that is
terrifying." Other members of the community laughed at anyone who thought their
source code was secure when hosted on a version control system like Github.

Immediately following news of the breach, investors and commenters on reddit
were calling for Github to refund all of the money to its investors. Github.com
could not be reached for comment, but they did release a special "Hackedocat"
to commemorate the occasion.

At press time, the top comments on Hacker News were from a person complaining
about how dumb this article is, another person explaining to everyone that this
article is satire, and a third person explaining that while he understands this
is satire, the article is "dumb" and "not that funny".
