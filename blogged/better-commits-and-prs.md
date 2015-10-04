# Stepping Up Your Pull Request Game

Okay! You had an idea for how to improve the project, the maintainers indicated
they'd approve it, you checked out a new branch, made some changes, and you are
ready to submit it for review. Here are some tips for submitting a changeset
that's more likely to pass through code review quickly, and make it easier for
people to understand your code.

#### A Very Brief Caveat

**If you are new to programming, don't worry about getting these details
right!** There are a lot of other useful things to learn first, like the
details of a programming language, how to test your code, how to retrieve
data you need, then parse it and transform it into a useful format. I started
programming by copy/pasting text into the Wordpress "edit file" UI.

## Write a Good Commit Message

A big, big part of your job as an engineer is *communicating what you're doing
to other people*. When you communicate, you can be more sure that you're
building the right thing, you increase usage of things that you've built, and
you ensure that people don't assign credit to someone else when you build
things. Part of this job is writing a clear message for the rest of the team
when you change something.

Fortunately you are probably already doing this! If you write a description of
your change in the pull request summary field, you're already halfway there.
You just need to put that great message in the commit instead of in the pull
request.

The first thing you need to do is stop typing `git commit -m "Updated the
widgets"` and start typing just `git commit`. Git will [try to open a text
editor][editor]; you'll want to configure this to use the editor of your
choice.

A lot of words have been written about writing good commit messages; [Tim Pope
wrote my favorite post][good-commit-message] about it.

How big should a commit be? Bigger than you think; I rarely use more than one
commit in a pull request, though I try to limit pull requests to 400 lines
removed or added, and sometimes break a multiple-commit change into multiple
pull requests.

### Logistics

If you use Vim to write commit messages, the editor will show you if the
summary goes beyond 50 characters.

<img src="https://api.monosnap.com/rpc/file/download?id=djSggWn3VVaax0oX4TCiM2B85jYdcO" />

If you write a great commit message, and the pull request is one commit, Github
will display it straight in the UI! Here's an example commit in the terminal:

<img src="https://api.monosnap.com/rpc/file/download?id=hH2KbssWBXA9LSh6TxxWgo85KUHqLt" />

And here's what that looks like when I open that commit as a pull request in
Github - note Github has autofilled the subject/body of the message.

<img src="https://api.monosnap.com/rpc/file/download?id=EelqgWluravE3MyE8BxBIzt0AQPQ6I" />

Note if your summary is too long, Github will truncate it:

<img src="https://api.monosnap.com/rpc/file/download?id=yPSDb5wyED1fpNcpN6fXdQhh8NjJUE" />

## Review Your Pull Request Before Submitting It

Before you hit "Submit", **be sure to look over your diff** so you don't submit
an obvious error. In this pass you should be looking for things like typos,
syntax errors, and debugging print statements which are left in the diff. One
last read through can be really useful.

Everyone struggles to get code reviews done, and it can be frustrating for
reviewers to find things like print statements in a diff. They might be more
hesitant to review your code in the future if it has obvious errors in it.

## Make Sure The Tests Pass

If the project has tests, try to verify they pass before you submit your
change. It's annoying that Github doesn't make the test pass/failure state more
obvious before you submit.

Hopefully the project has a test convention - a `make test` command in a
Makefile, instructions in a CONTRIBUTING.md, or automatic builds via Travis
CI. If you can't get the tests set up, or it seems like there's an unrelated
failure, add a separate issue explaining why you couldn't get the tests
running.

If the project has clear guidelines on how to run the tests, and they fail on
your change, it can be a sign you weren't paying close enough attention.

## The Code Review Process

I don't have great advice here, besides a) patience is a virtue, and b)
the faster you are to respond to feedback, the easier it will go for
reviewers. Really you should just read Glen Sanford's [excellent post on code
review][code-review].

## Ready to Merge

Okay! Someone gave you a LGTM and it's time to merge. As a part of the code
review process, you may have ended up with a bunch of commits that look like
this:

<img src="https://api.monosnap.com/rpc/file/download?id=ETMOMIDqWL6cOFW9jebJ9eLx67at3h" />

These commits are detritus, the prototypes of the creative process, and they
shouldn't be part of the permanent record. Why fix them? Because six months
from now, when you're staring at a piece of confusing code and trying to figure
out why it's written the way it is, you really want to see a commit message
explaining the change that looks like [this][good-commit], and not one that
says "fix tests".

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/jmhodges">@jmhodges</a> In case of a fire, I want a map to the exit. Not the architect&#39;s napkin sketch.</p>&mdash; Ben Sandofsky (@sandofsky) <a href="https://twitter.com/sandofsky/status/626127134801530880">July 28, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

There are two ways to get rid of these:

### Git Amend

If you just did a commit and have a new change that should be part of the same
commit, use `git amend` to add changes to the current commit. If you don't need
to change the message, use `git amend --no-edit` (I map this to `git alter` in
[my git config][git-config]).

### Git Rebase

You want to squash all of those typo fix commits into one. [Steve Klabnik has a
good guide][klabnik] for how to do this. I use this script, saved as `rb`:

<p>
[bash]
    local branch="$1"
    if [[ -z "$branch" ]]; then
        branch='master'
    fi
    BRANCHREF="$(git symbolic-ref HEAD 2>/dev/null)"
    BRANCHNAME=${BRANCHREF##refs/heads/}
    if [[ "$BRANCHNAME" == "$branch" ]]; then
        echo "Switch to a branch first"
        exit 1
    fi
    git checkout "$branch"
    git pull origin "$branch"
    git checkout "$BRANCHNAME"
    if [[ -n "$2" ]]; then
        git rebase "$branch" "$2"
    else
        git rebase "$branch"
    fi
    git push origin --force "$BRANCHNAME"
[/bash]
</p>

If you run that with `rb master`, it will pull down the latest `master` from
origin, rebase your branch against it, and force push to your branch on origin.
Run `rb master -i` and select "squash" to squash your commits down to one.

As a side effect of rebasing, you'll resolve any merge conflicts that have
developed between the time you opened the pull request and the merge time! This
can take the headache away from the person doing the merge, and help prevent
mistakes.

[editor]: http://stackoverflow.com/q/2596805/329700
[good-commit-message]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[code-review]: http://glen.nu/ramblings/oncodereview.php
[good-commit]: https://github.com/golang/go/commit/74245b03534dfec5f719aa60e03c0b932aa63e26
[klabnik]: http://blog.steveklabnik.com/posts/2012-11-08-how-to-squash-commits-in-a-github-pull-request
[git-config]: https://bitbucket.org/kevinburke/small-dotfiles/src/f5a786bbca89c2399d07ee2d49a77eba0ba06865/.gitconfig?at=master#.gitconfig-26
