# Don't use Sails (or Waterline)

The Shyp API currently runs on top of the [Sails JS framework][sails]. It's
an extremely popular framework - the project has over 11,000 stars on Github,
and it's one of the top 100 most popular projects on the site. However, we've
had a very poor experience with it, and with [Waterline][waterline], the ORM
that runs underneath it. Remember when you learned that `java.net.URL` [does a
DNS lookup to check whether a URL is equivalent to another URL][dns]? Imagine
finding an issue like that every two weeks or so and that's the feeling I get
using Sails and Waterline.

[sails]: https://sailsjs.org
[dns]: http://michaelscharf.blogspot.com/2006/11/javaneturlequals-and-hashcode-make.html
[waterline]: https://github.com/balderdashy/waterline

The project's maintainers are very nice, and considerate - we have our
disagreements about the best way to build software, but they're generally
responsive. It's also clear from the error handling in the project (at least
the getting started docs) that they've thought a lot about the first run
experience, and helping people figure out the answers to the problems they
encounter trying to run Sails.

That said, here are some of the things we've struggled with:

- The sailsjs.org website [broke all incoming Google links][google] ("sails
views", "sails models", etc), as well as about 60,000 of its own autogenerated
links, for almost a year. [Rachael Shaw][rachael] has been doing great work to
fix them again, but it was pretty frustrating that [documentation was so hard
to find][read] for that long.

- All POST and PUT requests that upload JSON or form-urlencoded data [sleep for
50ms in the request parser][sleep]. This sleep currently occupies about 30% of
the request time on our servers, and 50-70% of the time in controller tests.

- The community of people who use Sails doesn't seem to care much about
performance or correctness. The above defect was open for at least a year and
not one person wondered why simple POST requests take 50ms longer than a simple
GET. For a lot of the issues above and below it seems like we are the only
people who have ran into them, or care.

- By default Sails [generates a route for every function you define in a
controller][route], whether it's meant to be public or not. This is a huge
security risk, because you generally don't think to write policies for these
implicitly-created routes, so it's really easy to bypass any authentication
rules you have set up and hit a controller directly.

[route]: https://github.com/balderdashy/www.sailsjs.org/blob/688e909d156d0dc8aec071ce1a0c42cc33d3c016/config/blueprints.js#L30

- Blueprints are Sails's solution for a CRUD app and we've observed a lot of
unexpected behavior with them. For one example, passing an unknown column name
as the key parameter in a GET request (`?foo=bar`) will cause the server to
return a 500.

- If you want to test the queries in a single model, there's no way to do it
besides loading/lifting the entire application, which is [dog slow][dog-slow] -
on our normal sized application, it takes at least 7 seconds to begin running a
single test.

- Usually when I raise an issue on a project, the response is that there's some
newer, better thing being worked on, that I should use instead. I appreciate
that, but porting an application has lots of downside and little upside. I
also worry about the support and correctness of the existing tools that are
currently in wide use.

- [Hardcoded typos in command arguments][typos].

- No documented [responsible disclosure policy][policy], or information on how
security vulnerabilities are handled.

[policy]: https://github.com/balderdashy/sails/issues/2830
[typos]: https://github.com/balderdashy/sails/blob/master/bin/sails.js#L99

## Waterline

Waterline is the ORM that powers Sails. The goal of Waterline is to provide
the same query interface for any database that you would like to use.
Unfortunately, this means that the supported feature set is the least common
denominator of every supported database. We use Postgres, and by default this
means we can't get a lot of leverage out of it.

These issues are going to be Postgres oriented, because that's the database we
use. Some of these have since been fixed, but almost all of them (apart from
the data corruption issues) have bit us at one point or another.\*

- [No support for transactions][transactions]. We had to write our own
transaction interface completely separate from the ORM. (I hope to share it
soon)

- No support for custom Postgres types (bigint, bytea, array). If you set
a column to type `'array'` in Waterline, it creates a `text` field in the
database and serializes the array by calling `JSON.stringify`.

- Waterline offers a batch interface for creating items, e.g.
`Users.create([user1, user2])`. Under the hood, however, creating N items
issues N insert requests for one record each, instead of one large request. 29
out of 30 times, the results will come back in order, but there used to be a
race where sometimes `create` will [return results in a different order][order]
than the order you inserted them. This caused a lot of intermittent,
hard-to-parse failures in our tests until we figured out what was going on.

- Waterline queries are case insensitive; that is, `Users.find().where(name:
'FOO')` will turn into `SELECT * FROM users WHERE name = LOWER('FOO');`.
There's no way to turn this off. If you ask Sails to generate an index for you,
[it will place the index on the uppercased column name][index], so your queries
will miss it. If you generate the index yourself, you pretty much have to use
the lowercased column value & force every other query against the database to
use that as well.

- The `.count` function used to work by pulling the entire table into memory
and checking the length of the resulting array.

- No way to split out queries to send writes to a primary and reads to a
replica. No support for canceling in-flight queries or setting a timeout on
them.

- The test suite is shared by every backend adapter; this makes it impossible
for the Waterline team to write tests for database-specific behavior or failure
handling (unique indexes, custom types, check constraints, etc). Any behavior
specific to your database is poorly tested at best.

- ["Waterline truncated a JOIN table"][join-table]. There are probably more
issues in this vein, but we excised all `.populate`, `.associate`, and
`.destroy` calls from our codebase soon after this, to reduce the risk of data
loss.

- When Postgres raises a uniqueness or constraint violation, the resulting
error handling is very poor. Waterline used to throw an object instead of
an Error instance, which means that Mocha *would not print anything* about
the error unless you called `console.log(new Error(err));` to turn it into
an Error. (It's since been fixed in Waterline, and I [submitted a patch to
Mocha][mocha] to fix this behavior, but we stared at empty stack traces for
at least six months before that). Waterline attempts to use regex matching to
determine whether the error returned by Postgres is a uniqueness constraint
violation, but the regex fails to match other types of constraint failures like
[NOT NULL errors or partial unique indexes][check].

- The error messages returned by validation failures are only appropriate to
display if the UI can handle newlines and bullet points. Parsing the error
message to display any other scenario is very hard; we try really hard to dig
the underlying `pg` error object out and use that instead. Mostly nowadays
we've been [creating new database access interfaces][new-interfaces] that wrap
the Waterline model instances and handle errors appropriately.

## Conclusion

I appreciate the hard work put in by the Sails/Waterline team and contributors,
and it seems like they're really interested in fixing a lot of the issues
above. I think it's just really hard to be an expert in [sixteen different
database technologies][techs], and write a good library that works with all of
them, especially when you're not using a given database day in and day out.

[techs]: https://github.com/balderdashy/waterline#community-adapters

You *can* build an app that's reliable and performant on top of Sails and
Waterline - we think ours is, at least. You just have to be really careful,
avoid the dangerous parts mentioned above, and verify at every step that the
ORM and the router are doing what you think they are doing.

The sad part is that in 2015, you have **so many options** for building a
reliable service, that let you write code securely and reliably and can scale
to handle large numbers of open connections with low latency. Using a framework
and an ORM doesn't mean you need to enter a world of pain. You don't need to
constantly battle your framework, or worry whether your ORM is going to delete
your data, or it's generating the correct query based on your code. **Better
options are out there!** Here are some of the more reliable options I know
about.

- Instagram used [Django][django] well through its $1 billion dollar
acquisition. Amazing community and documentation, and the project is incredibly
stable.

- You can use [Dropwizard][dropwizard] from either Java or Scala, and I
know from experience that it can easily handle hundreds/thousands of open
connections with incredibly low latency.

- Hell, [the Go standard library][go] has a lot of reliable, multi-threaded,
low latency tools for doing database reads/writes and server handling. The
third party libraries are generally excellent.

I'm not amazingly familiar with backend Javascript - this is the only
server framework I've used - but if I had to use Javascript I would check out
whatever the Walmart and the Netflix people are using to write Node, since they
need to care a lot about performance and correctness.

<sub>\*: If you are using a database without traditional support for
transactions and constraints, like Mongo, correct behavior is going to be very
difficult to verify. I wish you the best of luck. </sub>

[index]: https://github.com/balderdashy/sails-postgresql/issues/142
[google]: https://github.com/balderdashy/sails/issues/2594
[rachael]: https://github.com/rachaelshaw
[read]: https://www.youtube.com/watch?v=sQP_hUNCrcE&index=2&list=PLkQw3GZ0bq1JvhaLqfBqRFuaY108QmJDK
[dog-slow]: https://kev.inburke.com/kevin/node-require-is-dog-slow/
[hard-coded]: https://github.com/balderdashy/sails/issues/2505
[sleep]: https://github.com/balderdashy/sails/issues/3205
[order]: https://github.com/balderdashy/sails-postgresql/issues/128
[percent]: https://github.com/balderdashy/waterline/issues/899
[join-table]: https://github.com/balderdashy/waterline/issues/812
[mocha]: https://github.com/mochajs/mocha/pull/1848
[new-interfaces]: https://gist.github.com/kevinburkeshyp/54cdb9c78cecf9616418
[check]: https://github.com/balderdashy/sails-postgresql/issues/186
[transactions]: https://github.com/balderdashy/waterline/blob/master/lib/waterline/model/lib/defaultMethods/save.js#L47
[django]: http://instagram-engineering.tumblr.com/post/13649370142/what-powers-instagram-hundreds-of-instances
[dropwizard]: http://www.dropwizard.io/
[go]: https://golang.org/pkg/net/http/