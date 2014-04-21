# The SSL library ecosystem needs diversity

The Heartbleed bug was really bad for OpenSSL - it let you ask a server a
simple question like "How are you" and then have the server tell you anything
it wants (password data, private keys that could be used to decrypt all
traffic), and the server would have no idea it was happening.

A lot of people have said that [we should ditch OpenSSL][ditch] because
this bug is so bad, and because [there are parts of the codebase that are
odd][openssl-twitter], and would usually indicate bad programmers, except that
they are found in a library that is deployed everywhere.

 [openssl-twitter]: https://mobile.twitter.com/opensslfact
 [ditch]: http://queue.acm.org/detail.cfm?id=2602816

Ditching OpenSSL is not going to happen any time soon because it is the
standard implementation for any server that has to terminate SSL traffic, and
writing good crypto libraries is very difficult. So this is not a promising
approach.

However this bug and the subsequent panic (as well as the flood of emails
telling me to reset passwords etc) indicate **the problem with having every
software company in the world rely on the same** library. Imagine that there
were three different SSL software tools that each had a significant share of
the market. A flaw in one could affect, at most, the users of that library.
Diversification reduces the value of any one exploit and makes it more
difficult to find general attacks against web servers.

This diversity is what makes humans so robust against things like the Spanish
Flu, which killed ~100 million people but didn't make a dent on the overall
human population. Compare that with the banana, which is [susceptible to a
virus][banana-virus] that could wipe out the entire stock of bananas around the
world.

 [banana-virus]: http://www.independent.co.uk/news/world/politics/bananageddon-millions-face-hunger-as-deadly-fungus-decimates-global-banana-crop-9239464.html

You can see the benefits of diversity in two places. One, even inside the
OpenSSL project, users had different versions of the library installed on their
servers. This meant that servers that didn't have versions `1.0.1a-f` installed
(like Twilio) were not vulnerable, which was good.

The second is that servers use different programming languages and different
frameworks. This means that the series of Rails CVE's were very bad for Rails
deployments but didn't mean anything for anyone else (another good thing).

After Heartbleed I donated $100 to the OpenSSL Foundation, in part because it
is really important and in part because it's saved me from having to think
about encrypting communication with clients (most of the time) which is really,
really neat. I will **match** that donation to other SSL libraries, under these
conditions:

- The library's source code is available to the public.

- There is evidence that the code has been used in a production environment to
  terminate SSL connections.

- The project has [room for more funding][room].

This is not a very large incentive, but it's at least a step in the right
direction; if you want to join my pledge, I'll update the dollar amounts and
list your name in this post. A prize of $10 million put a rocket into space;
I'm hoping it will help spur diversity in the SSL ecosystem as well.

 [room]: http://www.givewell.org/international/technical/criteria/scalability

