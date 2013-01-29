# The Definitive Guide to API Client Libraries

My name's Kevin. I worked with Twilio's client libraries pretty much every day
for the last year and I wanted to share some of the wisdom I've gained from
doing so.

### Should you have helper libraries?

You should think about helper libraries as a more accessible interface to your
API. Your helper libraries expose the bare minimum that clients need to make
requests, hiding the details of your authentication scheme and URL structure
in exchange for the promise of "do X in N lines of code." If the benefits of a
more accessible interface outweigh the costs, do it.

If people are paying to access your API (Twilio, AWS, Sendgrid, Stripe, for
example), then you probably should write helper libraries. A more accessible
API translates directly into more revenue for your company.

If you're two founders in a garage somewhere, maybe not. The gap between
your company's success and failure is probably not a somewhat easier API
interface. Writing a helper library is a lot of work, maybe one to four
man-weeks depending on the size of your API and your familiarity with the
language in question.

You might not need a client library if your customers are all highly
experienced programmers. For example the other day I wrote my own client
for the [Recaptcha API][recaptcha]. I knew how I wanted to consume it and
learning/installing a Recaptcha library would have been unnecessary overhead.

You may also not need a client library if standard libraries have very good
HTTP clients. For example, [Requests][requests] dramatically lowers the
barrier for writing a client that uses [HTTP basic auth][auth]. Developers
who are familiar with Requests will have an easier time writing http clients.
Implementing HTTP Basic auth remains a large pain point in other languages.

[recaptcha]: https://developers.google.com/recaptcha/
[requests]: http://docs.python-requests.org/en/latest/
[auth]: http://en.wikipedia.org/wiki/Basic_access_authentication

### How should I design my helper libraries?

Realize that if you are writing a helper library, for many of your customers
the helper library *will* be the API. You should put as much care into its
design as you do your HTTP API. Here are a few guiding principles.

- If you've designed your API in a [RESTful way][rest], your API endpoints
should map very well to objects in your system. Translate these objects in a
straightforward way into object classes, with the obvious changes - translate
numbers in the API representation from strings into integers, and from date
strings such as "2012-11-05" into date objects.

- Your library should be flexible and I will illustrate this with a short
story. After much toil and effort, the Twilio SMS team was ready to ship
[support for Unicode messages][unicode]. As part of the change, we changed
the API's ['Content-Type'][content-type] header from `application/json` to
`application/json; charset=utf-8`. We rolled out Unicode SMS and there was much
rejoicing; fifteen minutes later, we found out we'd broken three of our helper
libraries, and there was much wailing and gnashing of teeth. It turns out the
libraries had a hard-coded check for an `application/json` content-type, and
[threw an exception when we changed the Content-Type header][changeset].

- Your library should complain loudly if there are errors. Per the point
on flexibility above, your HTTP API should validate inputs, not the client
library. For example let's say we had the library raise an error if you tried
to send an SMS with more than 160 characters in it. If Twilio ever wanted
to ship support for concatenated SMS messages, no one who had this library
installed would be able to send multi-message texts. Instead, let your HTTP API
do the validation and pass through errors in a transparent way.

- Your library use consistent naming schemes. For example, the convention for
updating resources should be the same everywhere. Hanging up a call and
changing an account's FriendlyName both represent the same concept, updating
a resource. You should have methods to update each that look like:

    $account->update('FriendlyName', 'blah');
    $call->update('Status', 'completed');

It's okay, even good, to have methods that map to readable verbs:

    $account->reserveNumber('+14105556789');
    $call->hangup();

However, these should always be thin wrappers around the `update()` methods.

    class Call {
        function hangup() {
            return $this->update('Status', 'completed');
        }
    }

Having only the readable-verb names is [a path that leads to madness][csharp].
It becomes much tougher to translate from the underlying HTTP request to code,
and much trickier to add new methods or optional parameters later.

- Your library should include a user agent with the library name and version
number, that you can correlate against your own API logs. Custom HTTP clients
rarely (read: never) will add their own user agent, and [standard library
maintainers don't like default user agents much][node].

- Your library **needs** to include installation instructions, preferably
written at a beginner level. Users have varying degrees of experience with
things you might take for granted, like package managers, and will try to run
your code in a variety of different environments (VPS, AWS, on old versions of
programming languages, behind a firewall without admin rights, etc). Any [steps
your library can take to make things easier][creds] are good. As an example, the
Twilio libraries include the [SSL cert][pem] necessary for connecting to the Twilio
API.

[changeset]: https://github.com/twilio/twilio-php/commit/784638f8342332440b1189663ff050826b8caf1d
[content-type]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.17
[csharp]: https://github.com/twilio/twilio-csharp/issues/46
[node]: https://github.com/joyent/node/issues/4552
[rest]: http://blog.steveklabnik.com/posts/2011-07-03-nobody-understands-rest-or-http
[unicode]: http://www.twilio.com/engineering/2012/11/08/adventures-in-unicode-sms
[creds]: https://github.com/twilio/twilio-python/blob/master/twilio/rest/__init__.py#L98
[pem]: https://github.com/twilio/twilio-php/blob/master/Services/cacert.pem

### How do I know my helper libraries are doing what I want?

The [Twilio API][api] has over 20 different endpoints, split into list
resources and instance resources, which support the HTTP methods GET, POST, and
sometimes DELETE. Let's say there are 50 different combinations of endpoints
and HTTP methods in total. Add in implementations for each helper library, and
the complexity grows very quickly - if you have 5 helper libraries you're
talking about 250 possible methods, all of which could have bugs.

One solution to this is to write a lot of unit tests. The problem is these take
a lot of time to write, and at some level you are going to have to mock out the
API, or stop short of making the actual API request. Instead we've taken the
following approach to testing.

1. Start with a valid HTTP request, and the parameters that go with it.
2. Parse the HTTP request and turn it into a piece of sample code that
   exercises an aspect of your helper library.
3. Run that code sample, and intercept the HTTP request made by the library.
4. Compare the output with the original HTTP request. 

This approach has the advantage of actually checking against the HTTP request
that gets made, so you can test things like URL encoding issues. You can reuse
the same set of HTTP requests across all of your libraries. The HTTP
"integration" tests will also detect actions that should be possible with the
API but are [not implemented in the client][java].

[java]: https://github.com/twilio/twilio-java/pull/70/files

You might think it's difficult to do automated code generation, but it actually
was not that much work, and it's very easy if you've written your library in a
consistent way. Here's a small sample that generates snippets for our Python
helper library.

    def process_instance_resource(self, resource, sid, method="GET", params=None):
        """ Generate code snippets for an instance resource """
        get_line = '{} = {}.get("{}")'.format(self.instance_name, self.base, sid)

        if method == "GET":
            interesting_line = 'print {}.{}'.format(self.instance_name,
                self.get_interesting_property(resource))
            return "\n".join([get_line, interesting_line])

        elif method == "POST":
            update_line = '{} = {}.update("{}", {})'.format(
                self.instance_name, self.base, sid, self.transform_params(params))
            interesting_line = 'print {}.{}'.format(
                self.instance_name, self.get_interesting_property(resource))
            return "\n".join([update_line, interesting_line])

        elif method == "DELETE":
            return '{}.delete("{}")'.format(self.base, sid)

        else:
            raise ValueError("Method {} not supported".format(method))

Generating code snippets has the added advantage that you can then easily embed
these into your customer-facing documentation, [as we've done in our
documentation][snippets].

[api]: http://www.twilio.com/docs/api/rest
[snippets]: http://www.twilio.com/docs/api/rest/available-phone-numbers#local-get-basic-example-1

### How do people use helper libraries?

While pretty much every resource gets used in the aggregate, individual
accounts tend to only use one or two resources. This suggests that your API is
only being referenced from one or two places within a customer's codebase.

### How should I document my helper library?

Per the point above, your library is probably being used in only one or two
places in a customer's codebase. This suggests your customer is [hiring your
API to do a specific job][jobs]. Your documentation hierarchy should be aligned
around those jobs.

[jobs]: http://hbswk.hbs.edu/item/6496.html

