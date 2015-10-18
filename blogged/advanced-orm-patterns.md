# Advanced Database Access Patterns for the ORM Developer

Adrian Colyer wrote [a great summary][colyer] of a recent paper by Peter
Bailis et al. In the paper the database researchers examine open source Rails
applications and observe that the applications apply constraints - foreign key
references, uniqueness constraints - in a way that's **not very performant or
correct.**

[colyer]: http://blog.acolyer.org/2015/09/04/feral-concurrency-control-an-empirical-investigation-of-modern-application-integrity/

I was pretty surprised to read about this! For the most part we have avoided
problems like this at <a href="https://shyp.com">Shyp</a>, and I didn't realize
how widespread this problem is; I certainly have written a lot of bad queries
in the past.

So! Let's learn some tips for writing better queries. Everything below
will help you write an application that is more *correct* - it will avoid
consistency problems in your data - and more *performant* - you should be able
to achieve the same results as Rails, with fewer queries!

*ps - The info below may be really obvious to you! Great! There are
a lot of people who aren't familiar with these techniques, as the paper above
indicates.*

## Use database constraints to enforce business logic

Say you define an ActiveRecord class that looks like this:

<p>
[ruby]
class User < ActiveRecord::Base
  validates :email, uniqueness: true
end
[/ruby]
</p>

What actually happens when you try to create a new user? It turns out Rails
will make 4 (four!) roundtrips to the database.

1. BEGIN a transaction.

2. Perform a SELECT to see if any other users have that email address.

3. If the SELECT turns up zero rows, perform an INSERT to add the row.

4. Finally, COMMIT the result.

This is pretty slow! It also increases the load on your application and your
database, since you need to make 4 requests for every INSERT. Bailis et al also
show that with your database's default *transaction isolation level*, it's
possible to [insert two records with the same key][colyer]. Furthermore, there
are some ActiveRecord queries which *skip the built-in validations*, as [Gary
Bernhardt discussed in his video, "Where Correctness Is Enforced"][bernhardt],
way back in 2012. Any query which inserts data and skips the validations can
compromise the integrity of your database.

[bernhardt]: https://www.destroyallsoftware.com/screencasts/catalog/where-correctness-is-enforced

What if I told you you can do the same insert in one query instead of four,
*and* it would be more correct than the Rails version? Instead of Rails's
migration, write this:

<p>
[sql]
CREATE TABLE users (email TEXT UNIQUE);
[/sql]
</p>

The `UNIQUE` is the key bit there; it adds a unique key on the table. Then,
instead of wrapping the query in a transaction, just try an INSERT.

<p>
[sql]
> insert into users (email) values ('foo@example.com');
INSERT 0 1
> insert into users (email) values ('foo@example.com');
ERROR:  duplicate key value violates unique constraint "users_email_key"
DETAIL:  Key (email)=(foo@example.com) already exists.
[/sql]
</p>

You'll probably need to add better error handling around the failure case - at
least we did, for [the ORM we use][sails]. But at any level of query volume, or
if speed counts (and it probably does), it's worth it to investigate this.

## Just Try the Write

Say you wanted to read a file. You *could* write this:

<p>
[python]
if not os.path.isfile(filename):
    raise ValueError("File does not exist")
with open(filename, 'r') as f:
    f.read()
    ...
[/python]
</p>

But that would still be vulnerable to a race! What if the OS or another thread
deleted the file between the `isfile` check and the `with open` line - the
latter would throw an `IOError`, which won't be handled. Far better to just try
to read the file and handle errors appropriately.

<p>
[python]
try:
    with open(filename, 'r') as f:
        f.read()
        ...
except IOError:
    raise ValueError("File does not exist")
[/python]
</p>

Say you have a foreign key reference - `phone_numbers.user_id` refers to
`users.id`, and you want to validate that the `user_id` is valid. You could do:

<p>
[python]
def write_phone_number(number, user_id):
    user = Users.find_by_id(user_id)
    if user is None:
        raise NotFoundError("User not found")
    Number.create(number=number, user_id=user_id)
[/python]
</p>

*Just try to write the number!* If you have a foreign key constraint in the
database, and the user doesn't exist, the database will tell you so. Otherwise
you have a race between the time you fetch the user and the time you create the
number.

<p>
[python]
def write_phone_number(number, user_id):
    try
        Number.create(number=number, user_id=user_id)
    except DatabaseError as e:
        if is_foreign_key_error(e):
            raise NotFoundError("Don't know that user id")
[/python]
</p>

[sails]: https://kev.inburke.com/kevin/dont-use-sails-or-waterline/

## Updates Should Compose

Let's say you have the following code to charge a user's account.

<p>
[python]
def charge_customer(account_id, amount=20):
    account = Accounts.get_by_id(account_id)
    account.balance = account.balance - 20
    if account.balance <= 0:
        throw new ValueError("Negative account balance")
    else
        account.save()
[/python]
</p>

Under the hood, here's what that will generate:

<p>
[sql]
SELECT * FROM accounts WHERE id = ?
UPDATE accounts SET balance = 30 WHERE id = ?;
[/sql]
</p>

So far, so good. But what happens if two requests come in to charge the account
at the same time? Say the account balance is $100

1. Thread 1 wants to charge $30. It reads the account balance at $100.

2. Thread 2 wants to charge $15. It reads the account balance at $100.

3. Thread 1 subtracts $30 from $100 and gets a new balance of $70.

4. Thread 2 subtracts $15 from $100 and gets a new balance of $85.

5. Thread 1 attempts to UPDATE the balance to $70.

6. Thread 2 attempts to UPDATE the balance to $85.

This is clearly wrong! The balance after $45 of charges should be $55, but it
was $70, or $85, depending on which UPDATE went last. There are a few ways to
deal with this:

- create some kind of locking service to lock the row before the read and
after you write the balance. The other thread will wait for the lock before it
reads/writes the balance. These are hard to get right and will carry a latency
penalty.

- Run the update in a transaction; this will create an implicit lock on
the row. If the transaction runs at the [SERIALIZABLE or REPEATABLE READ
levels][levels], this is safe. Note most databases will set the default
transaction level to READ COMMITTED, which won't protect against the issue
referenced above.

[levels]: http://www.postgresql.org/docs/9.4/static/transaction-iso.html

- Skip the SELECT and write a single UPDATE query that looks like this:

    <p>
    [sql]
    UPDATE accounts SET balance = balance - 20 WHERE id = ?;
    [/sql]
    </p>

That last UPDATE is *composable*. You can run a million balance updates in any
order, and the end balance will be exactly the same, every time. Plus you don't
need a transaction or a locking service; it's exactly one write (and faster
than the `.save()` version above!)

*But if I do just one UPDATE, I can't check whether the balance will go below
zero!* You can - you just need to enforce the nonnegative constraint in the
database, not the application.

<p>
[sql]
CREATE TABLE accounts (
    id integer primary key,
    balance integer CHECK (balance >= 0),
);
[/sql]
</p>

That will throw any time you try to write a negative balance, and you can
handle the write failure in the application layer.

The key point is that your updates should be able to run in any order without
breaking the application. Use relative ranges - `balance = balance - 20` for
example - if you can. Or, only apply the UPDATE if the previous state of the
database is acceptable, via a WHERE clause. The latter technique is very useful
for state machines:

<p>
[sql]
UPDATE pickups SET status='submitted' WHERE status='draft' AND id=?;
[/sql]
</p>

That update will either succeed (if the pickup was in draft), or return zero
rows. If you have a million threads try that update at the same time, only one
will succeed - an incredibly valuable property!

### Beware of save()

The `save()` function in an ORM is really unfortunate for two reasons. First,
to call `.save()`, you have to retrieve an instance of the object via a
`SELECT` call. If you have an object's ID and some fields to read, you can
avoid needing to do the read by just trying the UPDATE. This introduces more
latency and the possibility of writing stale data.

Second, some implementations of `.save()` will issue an UPDATE and *update
every column*.

This can lead to updates getting clobbered. Say two requests come in, one to
update a user's phone number, and the other to update a user's email address,
and both call `.save()` on the record.

<p>
[sql]
UPDATE users SET email='oldemail@example.com', phone_number='newnumber' WHERE id = 1;
UPDATE users SET email='newemail@example.com', phone_number='oldnumber' WHERE id = 1;
[/sql]
</p>

In this scenario the first UPDATE gets clobbered, and the old email gets
persisted. This is really bad! We told the first thread that we updated the
email address, and then we overwrote it. Your users and your customer service
team will get really mad, and this will be really hard to reproduce. Be wary of
`.save` - if correctness is important (and it should be!), use an UPDATE with
only the column that you want.

## Partial Indexes

If you thought the previous section was interesting, check this out. Say
we have a pickups table. Each pickup has a driver ID and a status (DRAFT,
ASSIGNED, QUEUED, etc).

<p>
[sql]
CREATE TABLE pickups (
    id integer,
    driver_id INTEGER REFERENCES drivers(id),
    status TEXT
);
[/sql]
</p>

We want to enforce a rule that a given driver can only have one ASSIGNED pickup
at a time. You can do this in the application by using transactions and writing
very, very careful code... or you can ask Postgres to do it for you:

<p>
[sql]
CREATE INDEX "only_one_assigned_driver" ON pickups(driver_id) WHERE
    status = 'ASSIGNED';
[/sql]
</p>

Now watch what happens if you attempt to violate that constraint:

<p>
[sql]
> INSERT INTO pickups (id, driver_id, status) VALUES (1, 101, 'ASSIGNED');
INSERT 0 1
> INSERT INTO pickups (id, driver_id, status) VALUES (2, 101, 'DRAFT');
INSERT 0 1 -- OK, because it's draft; doesn't hit the index.
> INSERT INTO pickups (id, driver_id, status) VALUES (3, 101, 'ASSIGNED');
ERROR:  duplicate key value violates unique constraint "only_one_assigned_driver"
DETAIL:  Key (driver_id)=(101) already exists.
[/sql]
</p>

We got a duplicate key error when we tried to insert a second `ASSIGNED`
record! Because you can trust the database to not ever screw this up, you have
more flexibility in your application code. Certainly you don't have to be as
careful to preserve the correctness of the system, since it's impossible to put
in a bad state!

## Summary

In many instances your ORM may be generating a query that's both slow, and can
lead to concurrency errors. That's the bad news. The good news is **you can
write database queries that are both faster and more correct!**

A good place to start is by reversing the traditional model of ORM development.
Instead of starting with the code in the ORM and working backwards to the
query, start with the query you want, and figure out how to express than in
your ORM. You'll probably end up using the lower-level methods offered by your
ORM a lot more, and you'll probably discover defects in the way that your ORM
handles database errors. That's okay! You are on a much happier path.

*Thanks to [Alan Shreve][shreve] and [Kyle Conroy][conroy] for reading drafts
of this post.*

[shreve]: https://inconshreveable.com/
[conroy]: https://kyleconroy.com/
