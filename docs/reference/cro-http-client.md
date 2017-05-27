# Cro::HTTP::Client

The `Cro::HTTP::Client` class provides a flexible HTTP and HTTPS client
implementation, scaling from simple to more complex use cases. It can be
consumed in two ways:

* By making calls on the type object (`Cro::HTTP::Client.get($url)`). This
  is good for one-off requests, but does not provide connection re-use when
  making multiple requests to the same server (such as by using keep-alive).
* By making an instance of `Cro::HTTP::Client`. By default, this enables
  re-use of a pool of connections. It may also be configured with a default
  base URL, default authorization data to pass along, and even middleware to
  insert into the request/response processing pipeline. An instance of
  `Cro::HTTP::Client` may be used concurrently.

## Making Basic Requests

The `get`, `post`, `put`, `delete`, and `head` methods may be called on either
the type object or an instance of `Cro::HTTP::Client`. They will all return a
`Supply`. Since by default only a single HTTP response will be produced, it is
possible to `await` it:

    my $resp = await Cro::HTTP::Client.get('https://www.perl6.org/');

The response will be provided as a `Cro::HTTP::Response` object. It will be
produced as soon as the request headers are available; the body may not yet
have been received. By default, errors (4xx and 5xx status codes) will result
in an exception that does the `X::Cro::HTTP::Error` role, which has a
`response` property containing the `Cro::HTTP::Response` object.

    my $resp = await Cro::HTTP::Client.delete($product-url);
    CATCH {
        when X::Cro::HTTP::Error {
            if .response.status == 404 {
                say "Product not found!";
            }
            else {
                say "Unexpected error: $_";
            }
        }
    }

The actual exception type will be either `X::Cro::HTTP::Error::Client` for
4xx errors, and `X::Cro::HTTP::Error::Server` for 5xx errors (which is useful
when setting up retries that should distinguish server errors from client
errors).

### Getting the Response Body

The response body is always provided asynchronously, either by a `Promise` (if
requesting the enitre body) or a `Supply` (when the body is to be delivered as
it arrives).

To get the entire response body as a `Blob`, use the `body-blob` method:

    my Blob $body = await $resp.body-blob();

To get the entire response body as a `Str`, use the `body-text` method:

    my Str $body = await $resp.body-text();

This method will look at the `Content-type` header to see if a `charset` is
specified, and decode the body using that. Otherwise, it will see if the body
starts with a [BOM](https://en.wikipedia.org/wiki/Byte_order_mark) and rely on
that. Failing that, the `default-enc` named parameter will be used, if passed:

    my Str $body = await $resp.body-text(:default-enc<latin-1>);

If it is not passed, the a heuristic will be used: if the body can be decoded
as `utf-8` then it will be deemed to be `utf-8`, and failing that it will be
decoded as `latin-1` (which can never fail as all bytes are valid).

It is also possible to get the body as it arrives, using the `body-stream`
method. This returns a `Supply` that emits a `Blob` whenever data arrives (if
the chunked transfer coding is used, then this will already have been handled
before the body is delivered).
