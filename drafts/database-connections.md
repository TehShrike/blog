# Mocking Database Connections in Go

It can be useful when writing tests to mock out connections to the database.
Writing tests that integrate with the database means that everyone who runs
your test suite also has to have a database configured. Reading and writing
from a database can be slow, and is impossible if you are targeting 1ms per
test. Furthermore, it can be easier to mock out the database result you want
(connection error, no results, etc) than to initialize the database in the
state necessary for the test.

In a static language, this is fairly easy - you can just monkey patch the
database connection function to return the expected result. In Go this is a
little bit more difficult; you can't just overwrite sql.QueryRow to return
whatever you want.

Instead you can use an *interface* to provide the flexibility you want. Say we
want to retrieve a User from the database, the "easy" way would be something
like this:

<p>
[go]
var userQuery = `SELECT email, password from users WHERE id = $1`
var databaseUrl = "postgres://localhost"

func checkPassword(userId string, password string) bool {
    db, _ = sql.Open("postgres", databaseUrl)
    var email, hashedPassword string
    db.QueryRow(userQuery).Scan(&email, &hashedPassword)
    return passwordMatches(password, hashedPassword)
}
[/go]
</p>

However, this isn't very flexible. To test this method, you would need to
write one user record to the database with a bad password, and one with a good
password, so the function can fetch the user and compare passwords.

Instead imagine that we have a Datastore interface, and two implementations:

<p>
[go]
type Datastore interface {
    GetUser(string) User
}

type PostgresDatastore struct{}

func (pd PostgresDatastore) GetUser(id string) {
    db, _ = sql.Open("postgres", databaseUrl)
    var email, hashedPassword string
    db.QueryRow(userQuery).Scan(&email, &hashedPassword)
    return User{email: email, password: hashedPassword}
}

type DummyDatastore struct{}

func (dd DummyDatastore) GetUser(id string) User {
    return User{email: "kev@inburke.com", password: "hunter2"}
}
[/go]
</p>

We need to update our function as well to take a Datastore as an argument:

<p>
[go]
function checkPassword(ds Datastore, userId string, password string) bool {
    user := ds.GetUser()
    return passwordMatches(user.password, password)
}
[/go]

Now we can write a test that uses this

<p>
[go]
func TestPassword

[/go]
</p>
