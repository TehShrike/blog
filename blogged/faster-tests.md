Yesterday I sped up our unit/integration test runs from 16 minutes to 3 minutes.
I thought I'd share the techniques I used during this process.

- We had a hunch that an un-mocked network call was taking 3 seconds to time
  out. I patched this call throughout the test code base. It turns out this did
  not have a significant effect on the runtime of our tests, but it's good to
  mock out network calls anyway, even if they fail fast.

- I ran a profiler on the code. Well that's not true, I just timed various parts
  of the code to see how long they took, using some code like this:

    [python]
    import datetime
    start = datetime.datetime.now()
    some\_expensive\_call()
    total = (datetime.datetime.now() - start).total\_seconds()
    print "some\_expensive\_call took {} seconds".format(total)
    [/python]

    It took about ten minutes to zero in on the fixture loader, which was doing
    something like this:

    [python]
    def load\_fixture(fixture):
        model = find\_fixture\_in\_db(fixture['id'])
        if not model:
            create\_model(**fixture)
        else:
            update\_model(model, fixture)
    [/python]

    The call to `find_fixture_in_db` was doing a "full table scan" of our SQLite
    database, and taking about half of the run-time of the integration tests.
    Moreover in our case it was completely unnecessary, as we were deleting and
    re-inserting everything with every test run.

    I added a flag to the fixture loader to skip the database lookup if we
    were doing all inserts. This sped up observed test time by about 35%.

- I noticed that the local test runner and the Jenkins build runner were running
different numbers of tests. This was really confusing. I ended up doing some
fancy stuff with the xunit xml output to figure out which extra tests were
running locally. Turns out, the same test was running multiple times. The
culprit was a stray line in our Makefile:

    [bash]
    nosetests tests/unit tests/unit/* ...
    [/bash]

    The `tests/unit/*` change was running all of the tests in compiled `.pyc`
    files as well! I felt dumb because I actually added that `tests/unit/*`
    change about a month ago, thinking that nosetests wasn't actually running
    some of the tests in subfolders of our repository. This change cut down on
    the number of tests run by a factor of 2, which significantly helped the
    test run time.

- The Jenkins package install process would remove and re-install the virtualenv
before every test run, to ensure we got up-to-date dependencies with every run.
Well that was kind of stupid, so instead we switched to running

    [bash]
    pip install --upgrade .
    [/bash]

on our setup.py file, which should pull in the correct version of dependencies
when they changed (most of them are specified either with double-equals, `==` or
greater-than, `>=`, signs). Needless to say, skipping the full test run every
time saved about three to four minutes.

- I noticed that `pip` would still uninstall and reinstall packages that were
already there. This happened for two reasons. One, our Jenkins box is running
an older version of `pip`, which doesn't have [this change][pip-changelog] from
`pip 1.1`:

    > Fixed issue #49 - pip install -U no longer reinstalls the same versions of packages. Thanks iguananaut for the pull request.

    I upgraded the `pip` and `virtualenv` versions inside of our virtualenv.

    Also, one dependency in our `tests/requirements.txt` would install the
    latest version of `requests`, which would then be overridden in `setup.py`
    by a very specific version of `requests`, every single time the tests
    ran. I fixed this by explicitly setting the `requests` version in the
    `tests/requirements.txt` file.

That's it! There was nothing major that was wrong with our process, just fixing
the way we did a lot of small things throughout the build. I have a couple of
other ideas to speed up the tests, including loading fewer fixtures per test
and/or instantiating some objects like Flask's test_client globally instead of
once per test. You might not have been as dumb as we were but you'll likely find
some speedups if you check your build process as well.

[pip-changelog]: http://www.pip-installer.org/en/1.4.1/news.html
