# Node `require` is dog slow

Our test environment takes 6-9 seconds to load before any tests get run.
I tire of this during the ~30 times I run the test suite a day,<sup><a
href="#1">1</a></sup> so I wanted to make it faster.

For better or worse, the API runs on [Sails.js][sails]. Before running
model/controller tests, a bootstrap file in our tests calls `sails.lift`.

<p>
[javascript]
require('sails').lift(function(err) {
    // Run the tests
});
[/javascript]
</p>

This `lift` call generates about 400 queries against Postgres to retrieve
database schema, that each look like this:

<p>
[sql]
SELECT x.nspname || '.' || x.relname as "Table", x.attnum
as "#", x.attname as "Column", x."Type", case x.attnotnull
when true then 'NOT NULL' else '' end as "NULL",
r.conname as "Constraint", r.contype as "C", r.consrc,
fn.nspname || '.' || f.relname as "F Key", d.adsrc as "Default"
FROM (SELECT c.oid, a.attrelid, a.attnum, n.nspname, c.relname,
a.attname, pg_catalog.format_type(a.atttypid, a.atttypmod) as "Type",
a.attnotnull FROM pg_catalog.pg_attribute a, pg_namespace n,
pg_class c WHERE a.attnum > 0 AND NOT a.attisdropped
AND a.attrelid = c.oid and c.relkind not in ('S','v')
and c.relnamespace = n.oid and n.nspname
not in ('pg_catalog','pg_toast','information_schema')) x
left join pg_attrdef d on d.adrelid = x.attrelid
and d.adnum = x.attnum left join pg_constraint r on r.conrelid = x.oid
and r.conkey[1] = x.attnum left join pg_class f on r.confrelid = f.oid
left join pg_namespace fn on f.relnamespace = fn.oid
where x.relname = 'credits' order by 1,2;
[/sql]
</p>


I'm not really sure [what those queries do][queries], since Sails seems to
ignore the schema that's already in the database when generating table queries.
Since we use the smallest, safest subset of the ORM we can find, I tried
commenting out the [`sails-postgresql` module code][psql] that makes those
queries to see if the tests would still pass, and the tests did pass... but the
load time was still slow.

The next step was to instrument the code to figure out what was taking so long.
I wanted to have the Sails loader log the duration of each part of the load
process, but this would have required a global variable, and a whole bunch of
calls to console.log. It turns out [the Unix function `ts`][ts] can do this for
you, if log lines are generated at the appropriate times. Basically, it's an
instant awesome tool for generating insight into a program's runtime, without
needing to generate timestamps in the underlying tool.

<p>
[bash]
NAME
       ts - timestamp input

SYNOPSIS
       ts [-r] [-i | -s] [format]

DESCRIPTION
       ts adds a timestamp to the beginning of each line of input.
[/bash]
</p>

I set the Sails logging level to `verbose` and piped the output through `ts
'[%Y-%m-%d %H:%M:%.S]'`. I pretty quickly found a culprit..

<p>
[bash]
[2015-04-19 21:53:45.730679] verbose: request hook loaded successfully.
[2015-04-19 21:53:45.731032] verbose: Loading the app's models and adapters...
[2015-04-19 21:53:45.731095] verbose: Loading app models...
[2015-04-19 21:53:47.928104] verbose: Loading app adapters...
[2015-04-19 21:53:47.929343] verbose: Loading blueprint middleware...
[/bash]
</p>

That's a 2 second gap between loading the models and loading the
adapters.

I started adding profiling to the code near the "Loading app models..." line. I
expected to see that attaching custom functions (findOne, update, etc) to the
Sails models was the part that took so long. Instead I found out that [a module
called include-all][include] accounted for almost all of the 2.5 seconds. That
module simply requires every file in the `models` directory, about 30 files.

Further reading/logging revealed that [each `require` call was being generated
in turn][sync-calls]. *I've found it*, I thought, just `require` them all at
the same time and see a speedup. Unfortunately, the `require` operation is
synchronous in Node, so it doesn't matter if you [throw async pixie dust at
it][async-pixie-dust], the process can still only perform one `require` at a
time.

I tried just loading one model to see how slow that would be. This script took
an average of 700 milliseconds to run, on my high end Macbook Pro:

<p>
[javascript]
var start = Date.now();
require('api/models/Drivers');
console.log(Date.now() - start);
[/javascript]
</p>

700 milliseconds to require a model file, and that file's dependencies! I
can send a packet to and from New York 8 times in that amount of time. What
the hell is it actually doing? For this I turned to good old `strace` (or
[`dtruss`, as it's ported on Macs][dtruss]). First start up a shell to record
syscalls for any process that is called `node`.

<p>
[bash]
# (You'll want to kill any other node processes before running this.)
sudo dtruss -d -n 'node' > /tmp/require.log 2>&1
[/bash]
</p>

Open up another shell session and run your little script that calls `require`
and prints the startup time and then exits. You should have a few thousand
lines in a file called `/tmp/require.log`. Here's what I found near the start:

<p>
[bash]
   1186335 stat64("/Users/burke/code/api/api/models/node_modules/async\0", 0x7FFF5FBFE608, 0x9)             = -1 Err#2
   1186382 stat64("/Users/burke/code/api/api/models/node_modules/async.js\0", 0x7FFF5FBFE5B8, 0x9)          = -1 Err#2
   1186405 stat64("/Users/burke/code/api/api/models/node_modules/async.json\0", 0x7FFF5FBFE5B8, 0x9)                = -1 Err#2
   1186423 stat64("/Users/burke/code/api/api/models/node_modules/async.node\0", 0x7FFF5FBFE5B8, 0x9)                = -1 Err#2
   1186438 stat64("/Users/burke/code/api/api/models/node_modules/async.coffee\0", 0x7FFF5FBFE5B8, 0x9)              = -1 Err#2
   1186473 open("/Users/burke/code/api/api/models/node_modules/async/package.json\0", 0x0, 0x1B6)           = -1 Err#2
   1186501 stat64("/Users/burke/code/api/api/models/node_modules/async/index.js\0", 0x7FFF5FBFE5B8, 0x1B6)          = -1 Err#2
   1186519 stat64("/Users/burke/code/api/api/models/node_modules/async/index.json\0", 0x7FFF5FBFE5B8, 0x1B6)                = -1 Err#2
   1186534 stat64("/Users/burke/code/api/api/models/node_modules/async/index.node\0", 0x7FFF5FBFE5B8, 0x1B6)                = -1 Err#2
   1186554 stat64("/Users/burke/code/api/api/models/node_modules/async/index.coffee\0", 0x7FFF5FBFE5B8, 0x1B6)              = -1 Err#2
   1186580 stat64("/Users/burke/code/api/api/node_modules/async\0", 0x7FFF5FBFE608, 0x1B6)          = -1 Err#2
   1186598 stat64("/Users/burke/code/api/api/node_modules/async.js\0", 0x7FFF5FBFE5B8, 0x1B6)               = -1 Err#2
   1186614 stat64("/Users/burke/code/api/api/node_modules/async.json\0", 0x7FFF5FBFE5B8, 0x1B6)             = -1 Err#2
   1186630 stat64("/Users/burke/code/api/api/node_modules/async.node\0", 0x7FFF5FBFE5B8, 0x1B6)             = -1 Err#2
   1186645 stat64("/Users/burke/code/api/api/node_modules/async.coffee\0", 0x7FFF5FBFE5B8, 0x1B6)           = -1 Err#2
   1186670 open("/Users/burke/code/api/api/node_modules/async/package.json\0", 0x0, 0x1B6)          = -1 Err#2
   1186694 stat64("/Users/burke/code/api/api/node_modules/async/index.js\0", 0x7FFF5FBFE5B8, 0x1B6)                 = -1 Err#2
   1186712 stat64("/Users/burke/code/api/api/node_modules/async/index.json\0", 0x7FFF5FBFE5B8, 0x1B6)               = -1 Err#2
   1186727 stat64("/Users/burke/code/api/api/node_modules/async/index.node\0", 0x7FFF5FBFE5B8, 0x1B6)               = -1 Err#2
   1186742 stat64("/Users/burke/code/api/api/node_modules/async/index.coffee\0", 0x7FFF5FBFE5B8, 0x1B6)             = -1 Err#2
   1186901 stat64("/Users/burke/code/api/node_modules/async\0", 0x7FFF5FBFE608, 0x1B6)              = 0 0
   1186963 stat64("/Users/burke/code/api/node_modules/async.js\0", 0x7FFF5FBFE5B8, 0x1B6)           = -1 Err#2
   1187024 stat64("/Users/burke/code/api/node_modules/async.json\0", 0x7FFF5FBFE5B8, 0x1B6)                 = -1 Err#2
   1187050 stat64("/Users/burke/code/api/node_modules/async.node\0", 0x7FFF5FBFE5B8, 0x1B6)                 = -1 Err#2
   1187074 stat64("/Users/burke/code/api/node_modules/async.coffee\0", 0x7FFF5FBFE5B8, 0x1B6)               = -1 Err#2
      1656 __semwait_signal(0x10F, 0x0, 0x1)                = -1 Err#60
   1187215 open("/Users/burke/code/api/node_modules/async/package.json\0"0x0, 0x1B6)              = 11 0
[/bash]
</p>

That's a lot of wasted open()'s, and that's just to find one dependency.<sup><a
href="#2">2</a></sup> To load the single model, node had to open and read 300
different files,<sup><a href="#3">3</a></sup> and every require which wasn't
a relative dependency did the same find-the-node-module-folder dance. The
documentation seems to [indicate this is desired behavior][node], and [it
doesn't seem like there is any way around this][so].

Now, failed stat's are not the entire reason require is slow, but if I am
reading the timestamps correctly in the strace log, they are a fair amount of
it, and the most obviously wasteful thing. I could rewrite every `require`
to be relative, e.g. `require('../../node_modules/async')` but that seems
cumbersome and wasteful, when I can define the exact rule I want before hand:
if it's not a relative file path, look in `node_modules` in the top level of
my project.

So that's where we are; `require` for a single model takes 700 milliseconds,
`require` for all the models takes 2.5 seconds, and there don't seem to be
great options for speeding that up. There's some [discouraging discussion
here from core developers about the possibility of speeding up module
import][groups].

You are probably saying "load fewer dependencies", and you are right and
I would love to, but that is not an option at this point in time, since
"dependencies" basically equals Sails, and while we are trying to move off
of Sails, we're stuck on it for the time being. Where I can, I write tests
that work with objects in memory and don't touch our models/controllers, but
[Destroy All Software videos][das] only get you so far.

I will definitely think harder about importing another small module vs. just
copying the code/license wholesale into my codebase, and I'll definitely look
to add something that can warn about unused imports or variables in the code
base.

I'm left concluding that importing modules in Node is dog slow. Yes, 300
imports is a lot, but a 700ms load time seems way too high. Python imports can
be slow, but as far as I remember, it's mostly for things that compile C on the
fly, and for everything else you can work around it by rearranging `sys.path`
to match the most imports first (impossible here). If there's anything I can do
- some kind of compile option, or saving the V8 bytecode or something, I'm open
to suggestions.

<sup id="1">1. If you follow along with the somewhat-crazy convention of crashing
your Node process on an error and having a supervisor restart it, that means
that your server takes 6-9 seconds of downtime as well.</sup>

<sup id="2">2. The story gets even worse if you are writing Coffeescript, since
`require` will also look for files matching `.litcoffee` and `.coffee.md` at
every level. You can hack `require.extensions` to delete these keys.</sup>

<sup id="3">3. For unknown reasons, node occasionally decided not to stat/open
some imports that were require'd in the file.</sup>

[so]: http://stackoverflow.com/q/29738418/329700
[groups]: https://groups.google.com/forum/#!topic/nodejs/52gksIpgX4Q
[queries]: https://github.com/balderdashy/sails-postgresql/blob/master/lib/adapter.js#L125
[sails]: https://github.com/balderdashy/sails/issues/2594
[ts]: http://unix.stackexchange.com/a/26797/9519
[include]: https://github.com/balderdashy/include-all
[sync-calls]: https://github.com/balderdashy/include-all/blob/master/index.js#L44
[async-pixie-dust]: http://stackoverflow.com/a/20528452/329700
[dtruss]: https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/dtruss.1m.html
[das]: https://www.destroyallsoftware.com/screencasts/catalog/fast-tests-with-and-without-rails
[psql]: https://github.com/balderdashy/sails-postgresql
[node]: https://nodejs.org/api/modules.html#modules_loading_from_node_modules_folders
