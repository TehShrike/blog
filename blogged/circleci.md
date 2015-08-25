# Logging Database Queries in CircleCI

Our test suite has been failing maybe 2% of the time with a pretty opaque error
message. I thought the database logs would have more information about the
failure so I figured out how to turn them on with Circle.

Add the following to the `database` section of your `circle.yml`:

<pre><code>
database:
  override:
    - sudo sed -i "s/#logging_collector = off/logging_collector = on/" /etc/postgresql/9.4/main/postgresql.conf
    - sudo sed -i "s/#log_statement = 'none'/log_statement = 'all'/" /etc/postgresql/9.4/main/postgresql.conf
    - sudo sed -i "s/#log_duration = off/log_duration = on/" /etc/postgresql/9.4/main/postgresql.conf
    - sudo sed -i "s/#log_disconnections = off/log_disconnections = on/" /etc/postgresql/9.4/main/postgresql.conf
    - sudo mkdir -p /var/lib/postgresql/9.4/main/pg_log
    - sudo chown -R postgres:postgres /var/lib/postgresql/9.4/main/pg_log
    - sudo service postgresql restart
</code></pre>

Those settings will:

- enable various logging settings in the Postgres config
- create the `pg_log` directory (Postgres can't write if the directory doesn't
  exist)
- change ownership of the directory to the postgres user
- restart Postgres (needed to enable logging).

Finally to trigger the error you're going to want to run the tests a bunch of
times.

<pre><code>
test:
  override:
    - while true; do your_test_command | tee -a test.log ; if [[ ${PIPESTATUS[0]} -ne 0 ]]; then break; fi; done; exit 1
</code></pre>

Note you need to use the `${PIPESTATUS}` array instead of `$?` because you're
piping the output of your test runner to the test log. You're going to want to
pipe the output of your test runner to the test log because Circle can't render
text beyond a certain threshold.

Finally, enable SSH on your build so you can view the test log
file you've been writing, and your database logs, which will be in
`/var/lib/postgresql/9.4/main/pg_log`.

Happy hunting!
