# Dead Simple State Machines

Let's talk about state machines. Do you have objects in your system that can be
in different states (accounts, invoices, messages, employees)? Do you have code
that updates these objects from one state to another? If so, you probably want
a state machine.

## What is a state machine?

At its root, a state machine defines the legal transitions between states in
your system, is responsible for transitioning objects between states, and
prevents illegal transitions.

## This sounds like unnecessary boilerplate; why do I need this?

(Some of these actually happened! Some are invented.)

Let's talk about some bad things that can happen if you *don't* have a state
machine in place.

- A user submits a pickup. We pick up the item and ship it out. Two weeks
later, a defect causes the app to resubmit the same pickup, and reassign a
driver, for an item that's already been shipped.

- Two users submit a pickup within a second of each other. Our routing
algorithm fetches available drivers, computes each driver's distance to the
pickup, and says the same driver is available for both pickups. We assign the
same driver to both pickups.

- A user submits a pickup. A defect in a proxy causes the submit request to
be sent multiple times. We end up assigning four drivers to the pickup, and
sending the user four text messages that their pickup's been assigned.

- An item is misplaced at the warehouse and sent straight to the packing
station. Crucial steps in the shipping flow get skipped.

- Code for updating the state of an object is littered between several
different classes and controllers, which handle the object in different parts
of its lifecycle. It becomes difficult to figure out how the object moves
between various states. Customer support tells you that an item is in a
particular state and it's very to figure out how it got there.

These are all *really* bad positions to be in! A lot of pain for you and a lot
of pain for your teams in the field.

## You are already managing state

Do you have code in your system that looks like this?

<p>
[python]
def submit(pickup_id):
    pickup = Pickups.find_by_id(pickup_id)
    if pickup.state != 'DRAFT':
        throw new StateError("Can't submit a pickup that isn't in draft")
    pickup.state = 'SUBMITTED'
    pickup.save()
    MessageService.send_message(pickup.user.phone_number, 'Your driver is on the way!')
[/python]
</p>

Congrats! By checking the state of the pickup before moving to the next state,
you're already managing the state of your system! You are (at least partially)
defining legal transitions between states. To avoid the issues listed above,
you'll want to consolidate all of the state management in one place in your
codebase.

## Okay, how should I implement the state machine?

You don't need a fancy library (too much complexity), you don't need a DSL. You
just need a dictionary and a single database query.

The dictionary is for defining transitions, allowable input states, and the
output state. Here's a simplified version of the state machine we use for
Pickups.

<p>
[python]
states = {
    submit: {
        before: ['DRAFT'],
        after:   'SUBMITTED',
    },
    assign: {
        before: ['SUBMITTED'],
        after:   'ASSIGNED',
    },
    cancel: {
        before: ['DRAFT', 'SUBMITTED', 'ASSIGNED'],
        after:   'CANCELED',
    },
    collect: {
        before: ['ASSIGNED'],
        after:   'COLLECTED',
    },
}
[/python]
</p>

Then you need a single function, `transition`, that takes an object ID, the
name of a transition, and (optionally) additional fields you'd like to set on
the object if you update its state.

The `transition` function looks up the transition in the `states` dictionary,
and generates a single SQL query:

<p>
[sql]
UPDATE table SET
    state = 'newstate',
    extraField1 = 'extraValue1'
WHERE
    id = $1 AND
    state IN ('oldstate1', 'oldstate2')
RETURNING *
[/sql]
</p>

If your UPDATE query returns a row, you successfully transitioned the item!
Return successfully from the function. If it returns zero rows, you *failed* to
transition the item. It can be tricky to determine why this happened, since you
don't know which (invalid) state the item was in that caused it to not match.
We cheat and fetch the record to give a better error message - there's a race
there, but we note the race in the error message, and it gives us a good idea
of what happened in ~98% of cases.

Note what you *don't* want to do - you don't want to update the object in
memory and then call `.save()` on it. Not only is `.save()` dangerous, but
fetching the item before you attempt to UPDATE it means you'll be vulnerable to
race conditions between two threads attempting to transition the same item to
two different states (or, twice to the same state).

Say you send a text message to a user after they submit their pickup - if two
threads can successfully call the `submit` transition, the user will get 2 text
messages. The UPDATE query above ensures that *exactly one* thread will succeed
at transitioning the item, which means you can (and want to) pile on whatever
only-once actions you like (sending messages, charging customers, assigning
drivers, &c) *after* a successful transition and ensure they'll run once.
For more about consistency, see [Weird Tricks to Write Faster, More Correct
Database Queries][tricks].

Being able to issue queries like this is one of the benefits of using a
relational database with strong consistency guarantees. Your mileage (and
the consistency of your data) may vary when attempting to implement a state
transition like this using a new NoSQL database. Note that with the latest
version of MongoDB, [it's possible to read *stale* data][stale], meaning that
(as far as I can tell) the WHERE clause might read out-of-date data, and you
can apply an inconsistent state transition.

## Final Warnings

A state machine puts you in a much better position with respect to the
consistency of your data, and makes it easy to guarantee that actions performed
after a state transition (invoicing, sending messages, expensive operations)
will be performed *exactly once* for each legal transition, and will be
rejected for illegal transitions. I can't stress enough how often this has
saved our bacon.

You'll still need to be wary of code that makes decisions based on other
properties of the object. For example, you might set a `driver_id` on the
pickup when you assign it. If other code (or clients) decide to make a decision
based on the presence or absence of the `driver_id` field, you're making a
decision based on the state of the object, but outside of the state machine
framework, and you're vulnerable to all of the bullet points mentioned above.
You'll need to be vigilant about these, and ensure all calling code is making
decisions based on the `state` property of the object, not any auxiliary
properties.

You'll also need to be wary of code that tries a read/check-state/write
pattern; it's vulnerable to the races mentioned above. Always always just try
the state transition and handle failure if it fails.

Finally, some people might try to sneak in code that just updates the object
state, outside of the state machine. Be wary of this in code reviews and try to
force all state updates to happen in the StateMachine class.

[tricks]: https://kev.inburke.com/kevin/faster-correct-database-queries/
[stale]: https://aphyr.com/posts/322-call-me-maybe-mongodb-stale-reads
