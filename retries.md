"Build software like a tank." I am not sure where I read this, but I think
about it a lot, especially when writing HTTP clients. Tanks are incredible
machines - they are designed to move rapidly and protect their inhabitants in
any kind of terrain, against enemy gunfire, or worse.

HTTP clients often run in unfriendly territory, because they usually involve
a network connection between machines. Connections can fail, packets can be
dropped, the other party may respond very slowly, or with a new unknown error
message, or they might even change the API from under you. All of this means
writing an HTTP client like a tank is difficult. Here are some examples of
things that a desirable HTTP client would do for you, that are never there by
default.

- If a request fails to reach the remote server, we would like to retry it no
matter what. We don't want to wait around for the server forever though, so we
want to set a timeout on the connection attempt.

- If we send the request but the remote server doesn't respond in a timely
manner, we want to retry it, but only on requests where it is safe to send the
request again - so called [idempotent requests][idempotency].

- If the server returns an unexpected response, we want to always retry if the
server didn't do any processing - a 429, 502 or a 503 response usually indicate
this - as well as all [idempotent requests][idempotency].

 [idempotency]: http://restcookbook.com/HTTP%20Methods/idempotency/

- Generally we want to sleep between retries to allow the remote
connection/server to recover, so to speak. To help prevent [thundering herd
problems,][thundering-herd] we usually sleep with an exponential back off.

 [thundering-herd]: http://en.wikipedia.org/wiki/Thundering_herd_problem

Here's an example of how you might code this:

<p>
[python]
def resilient_request(method, uri, retries):
    while True:
        try:
            resp = requests.request(method, uri)
            if resp.status < 300:
                break
            if resp.status in [429, 502, 503]:
                retries -= 1
                if retries <= 0:
                    raise
                time.sleep(2 ** (3 - retries))
                continue
            if resp.status >= 500 and method in ['GET', 'PUT', 'DELETE']:
                retries -= 1
                if retries <= 0:
                    raise
                time.sleep(2 ** (3 - retries))
                continue
        except (ConnectionError, ConnectTimeoutError):
            retries -= 1
            if retries <= 0:
                raise
            time.sleep(2 ** (3 - retries))
        except TimeoutError:
            if method in ['GET', 'PUT', 'DELETE']:
                retries -= 1
                if retries <= 0:
                    raise
                time.sleep(2 ** (3 - retries))
                continue
[/python]
</p>

Holy [cyclomatic complexity][mccabe], Batman! This suddenly got complex, and
the control flow here is not simple to follow, reason about, or test. Better
hope we caught everything, or we might end up in an infinite loop, or try to
access `resp` when it has not been set. There are some parts of the above code
that we can break into sub-methods, but you can't make the code too much more
compact than it is there, since most of it is control flow. It's also a pain to
write this type of code and verify its correctness; most people just try once,
as [this comment from the `pip` library][pip] illustrates. This is a shame and
the reliability of services on the Internet suffers.

[mccabe]: http://en.wikipedia.org/wiki/Cyclomatic_complexity
[pip]: https://github.com/pypa/pip/blob/develop/pip/download.py#L267

### A better way

[Andrey Petrov](http://shazow.net/) and I have been putting in a lot of work
make it really, really easy for you to write resilient requests in Python.
We pushed the complexity of the above code down into the [urllib3][urllib3]
library, closer to the request that goes over the wire. Instead of the above,
you'll be able to write this:

 [urllib3]: http://urllib3.readthedocs.org/en/latest/

<p>
[python]
def retry_callable(method, response):
    """ Determine whether to retry this
    return ((response.status >= 400 and method in IDEMPOTENT_METHODS)
            or response.status in (429, 503))
retry = urllib3.util.Retry(read=3, backoff_factor=2,
                           retry_callable=retry_callable)
http = urllib3.PoolManager()
resp = http.request(method, uri, retries=retry)
[/python]
</p>

You can pass a callable to the retries object to determine the retry behavior
you'd like to see. Alternatively you can use the convenience `method_whitelist`
and `codes_whitelist` helpers to specify which methods to retry.

<p>
[python]
retry = urllib3.util.Retry(read=3, backoff_factor=2,
                           codes_whitelist=set([429, 500]))
http = urllib3.PoolManager()
resp = http.request(method, uri, retries=retry)
[/python]
</p>

And you will get out the same results as the 30 lines above. urllib3 will do
all of the hard work for you to catch the conditions mentioned above, with sane
(read: non-intrusive) defaults.

This is coming soon to urllib3 (and with it, to Python Requests and pip). We
hope this makes it easier for you to write high performance HTTP clients in
Python, and appreciate your feedback!
