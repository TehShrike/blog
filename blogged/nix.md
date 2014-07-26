# Nix: caveat emptor

I'm setting up a new website, which gave me an excuse to try out [Nix][nix],
the stateless package manager, and [Docker][docker], the tool that lets you run
all of your apps in light-weight containers on a host.

Nix may be a great tool, and help you avoid the possibility of moving parts in
your builds, but there are still a lot of edges to smooth out, just simple
stuff to make it easier to figure out what's going on and build things.

## Installation

Installation was very easy! There are 2 choices - install an entire operating
system, or install just the package manager. You can't really deploy the
operating system to anything besides AWS, so I chose the package manager.

You install it with

<p>
[bash]
bash <(curl https://nixos.org/nix/install)
[/bash]
</p>

No wgetting sources, configuring installation directories, "Permission Denied"
errors, it just works and this is one of the main reasons I like this format
even if everyone yells all the time that it's a security risk. It is, but
there are no better ways to install things at the command line, currently.

## Trying it out

Here was where things started to go wrong. The obvious name of the command for
a tool named `nix` is `nix`, right?

    $ nix
    zsh: command not found: nix

    $ find /  -name nix -executable -type f
    No matches found

Okay, this is annoying, back into the docs to see what actually got installed
onto my system. From the install page, there's a link to [read more about
Nix][nix-about], but no link to a quickstart, or "Try it out", or anything like
that. I click "Help" and get this sentence:

<img src="https://api.monosnap.com/image/download?id=GHbTd5oXs1gapZ2GXGLGA1svc2k9W4" />

This makes me think I am going to need to parse a PDF to find the information I
need.

### The manual

I open the [very large Nix manual][manual]. Missed the section that said "Quick
Start" while scanning the Table of Contents, maybe because it came *before* the
chapter on "Installation". Instead I start reading "Basic package management".
The command I am looking for is `nix-env` and finally there is something I can
type into a shell and run, I'm not quite sure what this does, but this way
I can at least verify that it was installed properly:

<img src="https://api.monosnap.com/image/download?id=YGTlGruQbTH8lnQMTSyyCkPzSriphW" />

However, I don't get the same list of packages.

<p>
[bash]
[nix@gazelle ~]$ nix-env -qaf nixpkgs-version '*'
error: getting information about `/home/nix/nixpkgs-version': No such file or directory
[/bash]
</p>

This is frustrating, and the note ("nixpkgs-version is where you've unpacked
the release") is not very helpful, as nix handled the installation for me, and
I don't know where the release is unpacked.

At this point I abandon the manual and Google around for anyone who's tried
installing Nix. I find [a nice tutorial explaining how to install Nix,
search for packages and install them][tutorial]. Problem solved, and a
good reminder that [documentation should be designed for people that don't
read][documentation].

 [documentation]: https://www.youtube.com/watch?v=cC67PzBgRYE

Note, my DigitalOcean box with 512MB of memory was not enough to run Nix; I got
a "error: unable to fork: Cannot allocate memory" when I tried starting the
program, and had to add a 256MB swapfile.

## Seeing what else I can do

Normally when I download a new tool I'll pull up the help menu to see all of
the things that are possible with the command. For example, if you type `python
-h`, you get:

    usage: python [option] ... [-c cmd | -m mod | file | -] [arg] ...
    Options and arguments (and corresponding environment variables):
    -B     : don't write .py[co] files on import; also PYTHONDONTWRITEBYTECODE=x
    -c cmd : program passed in as string (terminates option list)
    -d     : debug output from parser; also PYTHONDEBUG=x
    -E     : ignore PYTHON* environment variables (such as PYTHONPATH)
    -h     : print this help message and exit (also --help)
    -i     : inspect interactively after running script; forces a prompt even
             if stdin does not appear to be a terminal; also PYTHONINSPECT=x

Nix doesn't provide anything for "-h", and typing "--help" pulls up the man
page, which has the information I want but is pretty heavy weight. Also, with
a new user running Bash, the man page came up without the ANSI escape sequences
getting escaped. Haven't figured out whether this is my problem or Nix's.

<img src="https://api.monosnap.com/image/download?id=JdgxGb1KaJAZiEX5h0ZmqrFUhZPZjJ" />

## The existence of an extraordinarily large footgun

One time I typed `nix-env --install` and hit Enter without specifying a
package. Nix was a second away from trying to install literally every single
package it has, over 5000 of them. This seems like something that *no one*
would want to do, yet it's currently extremely easy to do by accident.

## The most frustrating problem of the day

Soon after this, lots of network operations began failing with the cryptic
error message `20: unable to get local issuer certificate`. The answers on
StackOverflow and `curl.haxx.se` suggest that this is due to a certificate
not being there. I was very confused, because there was a certificate in
`/etc/ssl/certs`, other SSL operations were working just fine, and the `debug`
output from curl at the command line indicated it was using the certificate
bundle.

It finally took an `strace` command to see that the network requests were not
actually looking in `/etc/ssl/certs` for the certificate, but somewhere deep in
the `/nix` directory. Setting `GIT_SSL_CAINFO=/etc/ssl/certs/ca-bundle.crt` in
the environment fixed the issue. Once I figured this out, I [found people][1]
[complaining about this][2] [problem][3] [all over the place][4].

 [1]: https://github.com/NixOS/nixpkgs/issues/3332
 [2]: https://github.com/NixOS/nixpkgs/pull/659
 [3]: http://lists.science.uu.nl/pipermail/nix-dev/2011-July/006391.html
 [4]: http://lists.science.uu.nl/pipermail/nix-dev/2012-July/009559.html

This means the default installation of `git` and `curl` will certainly break
`git clone` for everyone, and really should ship with certificates, or at
least a big red warning when you download the package that you need to get an
up-to-date certificate store from somewhere.

## Conclusion

There is a stateless package manager, and it can download packages and all of
their dependencies. That's really cool, but for the moment there are quite a
few usability problems that make this really hard for people to get started
with.

 [nix-about]: http://nixos.org/nix/
 [nix]: http://nixos.org/
 [docker]: https://www.docker.com/
 [manual]: http://nixos.org/nix/manual
 [tutorial]: https://www.domenkozar.com/2014/01/02/getting-started-with-nix-package-manager/
