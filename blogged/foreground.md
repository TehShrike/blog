# Figure out when long-running jobs finish, without stopping them

You kick off a long running job - maybe a data migration script that operates
on a large data set, or you're copying a large file from one disk to another,
or from the Internet to your local computer.

Then a few minutes in, you realize the job is going to take longer than you
thought, and you'd like to trigger some action when it's done - notify you, or
remove a temp directory, or something.

Like this: `wget reallybigfile.com/bigfile.mp3 && say "file done downloading"`

But you can't queue an action without hitting Ctrl+C and restarting the
job, setting you back minutes or hours. Or can you?

With most modern shells on Unix, you can *suspend* the running process, and the
Unix machine will freeze the state of the process for you. Simply hit `Ctrl+Z`
while any process is running and you will get a message like this:

[bash]
$ sleep 10
^Z
[1]  + 72277 suspended  sleep 10
[/bash]

You can then resume it with [the `fg` command][fg], which tells Unix to resume
operations with the suspended process. You can then combine `fg` with the
notification command of your choice. So let's say you've suspended the process
with `Ctrl+Z`, you can bring it back to the foreground and attach actions
afterwards like so:

[bash]
fg; say -vzarvox "Job complete."
[/bash]

Of course, you can do whatever you want instead of using the `say` command;
trigger another long running operation or whatever.

I use this probably about once a day, it never fails and it's always useful.
Hope it helps you too!

 [fg]: http://en.wikipedia.org/wiki/Fg_(Unix)
