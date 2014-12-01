# Profiling ZSH startup time

Recently I had [a very weird problem with iTerm][problem] where new login
shells were being created with environment variables already present.
Restarting my machine made the issue go away, and I wasn't able to reproduce it
again.

But I got curious about how long ZSH spends in various parts of the startup
process. A new `/bin/bash` login shell loads instantaneously and I was
wondering why my ZSH startup was so slow, and if there was anything I could do
to make it faster. My goal was to get to a command prompt in under 100
milliseconds.

## What files run when you start a ZSH login shell?

In order, [your machine will load/execute the following files when ZSH
starts][startup]:

    /etc/zshenv
    ~/.zshenv
    /etc/zprofile
    ~/.zprofile
    /etc/zshrc
    ~/.zshrc
    /etc/zlogin
    ~/.zlogin

On my machine only `/etc/zshenv` (which adds paths in `/etc/paths*` to the
$PATH variable) and `~/.zshrc` actually existed, which simplified the problem
somewhat.

I used the following two scripts to check execution time. First, this snippet
logged the execution time of every command run by my startup script in
`~/tmp/startlog.<pid>`.

<p>
[bash]
    PROFILE_STARTUP=false
    if [[ "$PROFILE_STARTUP" == true ]]; then
        # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
        PS4=$'%D{%M%S%.} %N:%i> '
        exec 3>&2 2>$HOME/tmp/startlog.$$
        setopt xtrace prompt_subst
    fi
    # Entirety of my startup file... then
    if [[ "$PROFILE_STARTUP" == true ]]; then
        unsetopt xtrace
        exec 2>&3 3>&-
    fi
[/bash]
</p>

Essentially this prints the command that zsh is running before you run it. The
PS4 variable controls the output of this print statement, and allows us to
insert a timestamp each time we run it.

I then wrote a [short python script][script] to print all lines above a certain
threshold. This is okay, but can show a lot of detail and won't show you if one
line in your .zshrc is causing thousands of lines of execution, which take
a lot of time in total.

### Observations

At first I used the GNU `date` program in the PS4 prompt to get millisecond
information about the time, however this program consistently used 3
milliseconds to run, so it got costly to run it thousands of times during
system profiling.

The first thing you find is that shelling out is very expensive, especially
to high-level languages. Running something like `brew --prefix` takes 50
milliseconds which is half of the budget. I found that Autojump's shell loader
ran `brew --prefix` twice so I submitted [this pull request][pr] to cache the
output of that and run it again.

## Another timing method

Ultimately what I want is to time specific lines/blocks of my zshrc, instead of
get profiling information for specific lines. I did this by wrapping them in
`time` commands, like this:

<p>
[bash]
    { time (
        # linux
        (( $+commands[gvim] )) && {
            alias vi=gvim;
            alias svi='sudo gvim'
        }
        # set up macvim, if it exists
        (( $+commands[mvim] )) && {
            alias vi=mvim;
            alias svi='sudo mvim'
        }
    ) }
[/bash]
</p>

This will time commands in a sub-shell, which means that any environment
variables set in the sub-shell won't be set in the environment. However the
purpose is to get timing information and it's good enough for that.

## Lazy loading

By far the worst offenders were the various "Add this to your .zshrc" scripts
that I had added in the past - virtualenvwrapper, travis, git-completion,
autojump, pyenv, and more. I wanted to see if there was a way to load these
only when I needed them (I don't, frequently). Turns out there is! Most of
these set functions in zsh, so I can shadow them with my own functions in a
zshrc. Once the file with the actual function definition is sourced, it'll
replace the shim and I'll be fine. Here's an example for [autojump][autojump]:

<p>
[bash]
    function j() {
        (( $+commands[brew] )) && {
            local pfx=$(brew --prefix)
            [[ -f "$pfx/etc/autojump.sh" ]] && . "$pfx/etc/autojump.sh"
            j "$@"
        }
    }
[/bash]
</p>

Or for pyenv:

<p>
[bash]
pyenv() {
    eval "$( command pyenv init - )"
    pyenv "$@"
}
[/bash]
</p>

Essentially on the first invocation, these functions source the actual
definition and then immediately call it with the arguments passed in.

## Conclusion

Ultimately I was able to shave my zsh startup time from 670 milliseconds to
about 390 milliseconds and I have ideas on how to shave it further (rewriting
my [weirdfortune][weirdfortune] program in Go for example, to avoid the
Python/PyPy startup cost). You can probably get similar gains from examining
your own zshrc.

[problem]: https://code.google.com/p/iterm2/issues/detail?id=3328&sort=-id
[startup]: http://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/
[script]: https://bitbucket.org/kevinburke/small-dotfiles/src/c09252b66f4320d85576517abb53d14a2c731766/scripts/parse_zsh_startup.py?at=master
[pr]: https://github.com/joelthelion/autojump/pull/331
[weirdfortune]: https://github.com/kevinburke/weirdfortune
[autojump]: https://github.com/joelthelion/autojump
