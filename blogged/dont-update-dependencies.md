# Maybe Automatically Updating Dependencies Isn't a Great Idea

There's a distressing feeling in the Node.js community that apps without
up-to-date dependencies are somehow not as good, or stable, as apps
that always keep their dependencies up to date. So we see things like
[greenkeeper.io][greenkeeper] and [badges][gemnasium] that show whether the
project's [dependencies are up to date][gemnasium] (and, implicitly, shame
anyone whose dependencies aren't green).

[greenkeeper]: http://greenkeeper.io
[gemnasium]: https://gemnasium.com/

I'm not talking about updating dependencies for a good reason (covered below);
I'm talking about the practice of updating dependencies for the sake of keeping
the dependencies updated. In the best possible case, a dependency update does
*nothing*. The application keeps running exactly as it was. In the worst case,
your servers crash, millions of dollars of business value are affected, state
is compromised, or worse.

One day at Twilio we tried to deploy code that had a defect in it. The
deployment tool noticed the errors and tried to rollback the deployment by
putting the old nodes in the load balancer and taking the new ones out.
Except... when it went to take the new nodes out, the worker process crashed.
So we ended up with both the new (faulty) nodes and the old nodes in the load
balancer, and our most reliable tool for cluster management couldn't pull the
bad nodes out.

We did some investigation and it turns out one of our dependencies had updated.
Well, it wasn't a direct dependency - we locked down all of those - it was a
dependency of a dependency, which upgraded to version 3, and introduced an
incompatibility.

Fundamentally, updating dependencies is a dangerous operation. Most people
would never deploy changes to production without having them go through code
review, but I have observed that many feel comfortable bumping a package.json
number without looking at the diff of what changed in the dependency.

New releases of dependencies are usually less tested in the wild than older
versions. We know the best predictor of the number of errors in code is the
number of lines written. The current version of your dependency (which you know
works) has 0 lines of diff when compared with itself, but the newest release
has a greater-than-0 number of lines of code changed. Code changes are risky,
and so are dependency updates.

Errors and crashes introduced by dependency updates are difficult to debug.
Generally, the errors are not in your code; they're deep in a `node_modules`
or `site-packages` folder or similar. You are probably more familiar with your
application code than the intricacies of your third party tools. Tracking down
the error usually involves figuring out what version of the code used to be
running (not easy!) and staring at a diff between the two.

*But my tests will catch any dependency errors*, you say. Maybe you have great
coverage around your application. But do the dependencies you're pulling in
have good test coverage? Are the interactions between your dependencies tested?
How about the interactions between the dependency and every possible version of
a subdependency? Do your tests cover every external interface?

*But the dependencies I'm pulling in use semver, so I'll know if things
break.* This only saves you if you actually read the CHANGELOG, or the package
author correctly realizes a breaking change. Otherwise you get [situations
like this][request]. Which just seems sad; the reporter must have taken time
to update the package, then gotten an error report, then had to figure out
what change crashed the servers, then mitigated the issue. A lot of downside
there - wasted time and the business fallout of a crashing application, and
I'm struggling to figure out what benefit the reporter got from updating to the
latest possible version.

### When to Update Dependencies

Generally I think you should lock down the exact versions of every dependency
and sub-dependency that you use. However, there are a few cases where it makes
sense to pull in the latest and greatest thing. In every case, at the very
least I read the CHANGELOG and scan the package diff before pulling in the
update.

#### Security Upgrades

An application issues a new release to patch a security vulnerability, and you
need to get the latest version of the app to patch the same hole. Even here,
you want to ensure that the vulnerability actually affects your application,
and that the changed software does not break your application. You may not want
to grab the entire upstream changeset, but only port in the patch that fixes
the security issue.

#### Performance Improvement

Recently we noticed [our web framework was sleeping for 50ms][sails] on every
POST and PUT request. Of course you would want to upgrade to avoid this
(although we actually fixed it by removing the dependency).

#### You Need a Hot New Feature

We updated mocha recently because [it wouldn't print out stack traces for things
that weren't Error objects][trace]. We submitted a patch and upgraded mocha to
get that feature.

#### You Need a Bug Fix

Your version of the dependency may have a defect, and upgrading will fix the
issue. Ensure that the fix was actually coded correctly.

## A Final Warning

Updated dependencies introduce a lot of risk and instability into your project.
There are valid reasons to update and you'll need to weigh the benefit against
the risk. But updating dependencies just for the sake of updating them is just
going to run you into trouble.

**You can avoid all of these problems by not adding a dependency in the first
place**. Think really, really hard before reaching for a package to solve your
problem. Actually read the code and figure out if you need all of it or just
a subset. Maybe if you need to pluralize your application's model names, it's
okay to just add an 's' on the end, instead of adding the `pluralize` library.
Sure, the Volcano model will be Volcanos instead of Volcanoes but maybe that's
okay for your system.

Unfortunately my desired solution for adding dependencies - fork a library, rip
out the parts you aren't using, and copy the rest directly into your source
tree - isn't too popular. But I think it would help a lot with enforcing the
idea that you own your dependencies and the code changes inside.

[request]: https://github.com/request/request/issues/1786
[trace]: https://github.com/mochajs/mocha/pull/1848
[sails]: https://kev.inburke.com/kevin/dont-use-sails-or-waterline/
