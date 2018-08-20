# Cro::HTTP::Test

Tests for a Cro HTTP service can in principle be written by hosting the
application using `Cro::HTTP::Server`, using `Cro::HTTP::Client` to make
requests to it, and using the standard `Test` library to check the results.
This library makes writing such tests easier, and executing them faster, by:

* Providing a more convenient API for making test requests and checking the
  results
* Skipping the network and just passing `Cro::TCP` objects from the client
  pipeline to the server pipeline and vice versa

## A basic example

Given a module `MyService::Routes` that looks like:

```
sub routes() is export {
    route {
        get -> {
            content 'text/plain', 'Nothing to see here';
        }
        post -> 'add' {
            request-body 'application-json' => -> (:$x!, :$y!) {
                content 'application/json', { :result($x + $y) };
            }
        }
    }
}
```

We could write tests for it like this:

```
use Cro::HTTP::Test;
use MyService::Routes;

test-service routes(), {
    test get('/'),
        status => 200,
        content-type => 'text/plain',
        body => /nothing/;

    test-given '/add', {
        test post(json => { :x(37), :y(5) }),
            status => 200,
            json => { :result(42) };

        test post(json => { :x(37) }),
            status => 400;

        test get(json => { :x(37) }),
            status => 405;
    }
}

done-testing;
```

## Setting the service to test

The `test-service` function has two candidates.

The `test-service(Cro::Transform, &tests, :$fake-auth, :$http)` candidate
runs the tests against the HTTP application provided, which can be any
`Cro::Transform` that consumes a `Cro::HTTP::Request` and produces a
`Cro::HTTP::Response`. Applications that are written with `Cro::HTTP::Router`
do this. It is also possible to use `Cro.compose` to put (potentially mock)
middleware in place also. The optional `:$fake-auth` parameter, if passed,
will prepend a middleware that sets the `auth` of the request to the
specified object. This is useful for simulating a user or session and
thus testing authorization. The `http` argument specifies the HTTP version to
run the tests under. Since we control both client and server side in the test,
a setting of `:http<1.1 2>` is not allowed. The default is `:http<2>`.

The `test-service($uri, &tests)` candidate runs the tests against the specified
base URI, connecting to it through `Cro::HTTP::Client`. This makes it possible
to use `Cro::HTTP::Test` to write tests for services built using something other
than Cro.

All other named parameters are passed as `Cro::HTTP::Client` constructor
arguments.

## Writing tests

The `test` function is for use inside of the block passed to `test-service`.
It expects to be passed one positional argument representing the request to
test, and named parameters indicating the expected properties of the response.

The request is specified by calling one of `get`, `put`, `post`, `delete`,
`head`, or `patch`. There's also `request($method, ...)` for other HTTP methods
(in fact, `get` will just call `request('GET', ...)`). These functions accept
an optional positional parameter providing a relative URI, which if provided
will be appended to the current effective base URI. The `:$json` named parameter
is treated specially, expanding to `{ content-type => 'application/json`, body
=> $json)`. All other named parameters will be passed on to the `Cro::HTTP::Client`
`request` method, thus making all of the HTTP client's functionality available.

Named parameters to the `test` function constitute checks. They largely follow
the names of methods on the `Cro::HTTP::Response` object. The available checks
are as follows.

### status

Smartmatches the `status` property of the response against the
check. While an integer, such as `status => 200`, will be most common, it is
also possible to so things like `status => * < 400` (e.g. not an error).

### content-type

Checks the content-type is equivalent. If passed a string,  it parses it as a
media type and checks the type and subtype match that of the response. If
there are any extra parameters in the string (such as a charset), then these
will be checked for in the received media type also. If the received media type
has extra parameters that are not mentioned, then these will be disregarded.
Thus a check `content-type => 'text/plain'` matches `text/plain; charset=utf8`
in the response.

For more fine-grained control, pass a block, which will be passed an instance
of `Cro::MediaType` and expected to return someting truthy for the test to
pass.

### header or headers

Takes either a hash mapping header names to header values, or a list of `Pair`
doing the same. The test passes if the headers are present and the value of 
the header smartmatches against the value. Use `*` when only caring that the
header exists, but not wishing to check its values. All other headers in the
response will be ignored (that is, extra headers are considered fine).

```
    headers => {
        Strict-Transport-Security => *,
        Cache-Control => /public/
    }
```

For further control, pass a block, which will receive a `List` of `Pair`, each
one representing a header. Its return value should the truthy for the test to
pass.

### body-text

Obtains the `body-text` of the response and smart-matches it against the
provided value. A string, regex, or code object are all potentially useful.

```
    body-text => /:i success/
```

The body test will be skipped if there is a `content-type` tested and that
test fails.

### body-blob

Obtains the `body-blob` of the response and smart-matches it against the
provided value.

```
    body-blob => *.bytes > 128
```

The body test will be skipped if there is a `content-type` tested and that
test fails.

### body

Obtains the `body` of the response and smart-matches it against the provided
value. Note that the `body` property decides what to produce based on the
`content-type` of the response, thus picking an appropriate body parser. It
is thus recommended to use this together with `content-type` (that will always
be tested ahead of `body`, and the `body` test skipped if it fails).

### json

This is a convenience short-cut for the common case of a JSON response. It
imples `content-type => { .type eq 'application' && .subtype-name eq 'json'
|| .suffix eq 'json' }` (that is, it accepts `application/json` or something
like `application/vnd.foobar+json`).

If passed a code value, then the code will be invoked with the deserialized
JSON body and should return a truthy value for the test to pass. Otherwise,
the `is-deeply` test routine will be used to check the structure of the JSON
that was received matches what was expected.

## Many tests with one URI, set of headers, etc.

It can get tedious to repeat the same details of a test. For example, it is
common to wish to write many tests against the same URI, passing it a
different body or using different request methods each time. The `test-given`
function comes in various forms. It can be used with a URI and a block:

```
test-given '/add', {
    test post(json => { :x(37), :y(5) }),
        status => 200,
        json => { :result(42) };
    test post(json => { :x(37) }),
        status => 400;
}
```

In this case, the tests will all be performed against this URI appended to
the current effective URI, which in a `test-service` block is the base URI of
the service being tested. If the individual `test` cases have a URI too, it
will also be appended. It is possible to nest `test-given` blocks, and each
appends its URI segments, establishing a new current effective URI.

It is also possible to pass named parameters to `test-given`, and these will
be used as request parameters, passed along to `Cro::HTTP::Client`. Note that
any named parameters that are specified to `get` or `request` will override
those specified in `test-given`.

```
test-given '/add', headers => { X-Precision => '15' } {
    ...
}
```

The second form doesn't require a relative URI, and instead just takes options:

```
test-given headers => { X-Precision => '15' } {
    ...
}
```
