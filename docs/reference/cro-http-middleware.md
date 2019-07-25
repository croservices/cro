# Writing HTTP middleware

## What is HTTP middleware?

Cro services are formed by composing components to form asynchronous message
processing pipelines. A minimal HTTP/1.1 pipeline, built per connection, would
consist of the following components:

* A `Cro::HTTP::RequestParser`, which parses `Cro::TCP::Message` objects into
  HTTP requests and emits a `Cro::HTTP::Request` for each one
* The application (often expressed using `Cro::HTTP::Router`), which emits
  a `Cro::HTTP::Response`
* A `Cro::HTTP::ResponseSerializer`, which serializes `Cro::HTTP::Response`
  objects into one or more `Cro::TCP::Message` objects and emits them

Writing HTTP middleware means writing extra components to place into this
pipeline. There are numerous uses of middleware; some examples include:

* Adding extra security-related headers to responses
* Logging requests/responses
* Authentication
* Response caching
* Enforcing request rate limits

Middleware is the way the Cro processing pipeline can be customized to the
needs of a particular application.

While middleware is just a `Cro::Transform` (or a pair of them when both a
request and a response are involved), the `Cro::HTTP::Middleware` module
contains a number of convenience roles to factor out some of the boilerplate
from the most common middleware patterns.

## Choosing how to apply middleware

Middleware can be applied either:

* At `Cro::HTTP::Server` level, in which case it applies to all requests and
  responses processed by the service. There is a slight performance benefit to
  applying middleware at this level: the processing pipeline with server-level
  middleware is built per connection, and re-used for multiple requests with
  HTTP/1.1 persistent connections as well as with HTTP/2.0 where there is
  typically a single longer-lived connection per client.
* At the level of a `route` block (using `Cro::HTTP::Router`). When composing
  a larger application out of many `route` blocks, using `include` or
  `delegate`, this allows for more localized application of middleware (for
  example, authentication-related middleware need only be included in the
  processing of routes that need authentication).
* When assembling custom processing pipelines, by passing the middleware to
  `Cro.compose`. For example, supposing a GraphQL handler was used with
  `delegate` in a route block, and some middleware should apply just to it,
  then `delegate Cro.compose(TheMiddleware, GraphQLThing.new(...));` or some
  such would be used to build a pipeline to delegate to, containing both the
  piece of middleware and the GraphQL handler.

Note that the third case could also be done using an `include` of a nested
`route` block too:

```
include 'endpoint' => route {
    before-matched TheMiddleware;
    delegate GraphQLThing.new(...);
}
```

And there's no particularly strong reason to pick one over the other, if
already using `Cro::HTTP::Router`.

That leaves the main choice as being whether to put middleware at the server
or `route`-block level. As a rough guideline:

* If it is service-level infrastructure (such as logging or applying HSTS),
  then apply it at the server level.
* If it should only apply to some routes, then use the `include` and `delegate`
  features of `Cro::HTTP::Router` to segregate the routes where it applies, and
  apply the middleware at `route`-block level where needed.
* If it feels more like part of the application than infrastructure, lean
  towards putting it at the `route` block level.

## Implementing middleware

There are two options for implementing middleware:

* Implement it in a class. This allows the middleware to be applied at either
  server or `route`-block level, or composed into a custom pipeline. It is
  certainly the way to go if publishing the middleware as a module, and any
  configuration can be provided as constructor arguments. Since working this
  way involves writing a `supply` block to do the processing, it is easy to
  incorporate other asynchronous work (for example, querying a key/value store
  to get session data) without blocking other requests being processed on the
  same connection (this is of interest under HTTP/2.0, where many requests are
  multiplexed onto a single connection).
* Write it directly inside of a `Cro::HTTP::Router` `route` block, using the
  block forms of `before` and `after`. This is very convenient for one-off and
  simple middleware that is specific to that `route` block, and that isn't for
  re-use elsewhere.

For the first case, while one could implement a `Cro::Transform`, there are a
number of convenience roles that eliminate some pieces of boilerplate for the
most common cases.

### Simple request manipulation middleware

The `Cro::HTTP::Middleware::Request` role provides a convenient way to
implement simple HTTP request middleware. It does the `Cro::Transform` role
and implements all of its methods, leaving just the `process` method requiring
implementation.

The `process` method is passed a `Supply` of incoming requests, and should
return a `Supply` that the requests will be emitted into after processing.
One could write the processing using a `supply` block:

```
class UserAgentLog does Cro::HTTP::Middleware::Request {
    method process(Supply $requests) {
        supply whenever $requests -> $req {
            with $req.header('user-agent') -> $ua {
                log-the-user-agent($ua);
            }
            emit $req;
        }
    }
}
```

Take care to remember to `emit` the request after processing, or the pipeline
will hang. Alternatively, this case could be written using the `do` method on
a `Supply`, which does a side-effect and doesn't require emitting the request:

```
class UserAgentLog does Cro::HTTP::Middleware::Request {
    method process(Supply $requests) {
        $requests.do: -> $req {
            with $req.header('user-agent') -> $ua {
                log-the-user-agent($ua);
            }
        }
    }
}
```

### Simple response manipulation middleware

The `Cro::HTTP::Middleware::Response` role provides a convenient way to
implement response processing middleware. It does the `Cro::Transform` role
and implements all of its methods, and requires only that the `process`
method be implemented.

The `process` method is passed a `Supply` of responses, and should return a
`Supply` that the responses will be emitted into after processing. One could
write the processing using a `supply` block:

```
class HSTS does Cro::HTTP::Middleware::Response {
    has Int $.max-age = 31536000;

    method process(Supply $responses) {
        supply whenever $responses -> $rep {
            $rep.append-header: 'Strict-transport-security',
                "max-age=$!max-age"
            emit $rep;
        }
    }
}
```

Take care to `emit` the response after processing. Alternatively, simple
cases like this can be implemented using the `do` method on `Supply`, which
does a side-effect and then emits the response afterwards:

```
class HSTS does Cro::HTTP::Middleware::Response {
    has Int $.max-age = 31536000;

    method process(Supply $responses) {
        $responses.do: -> $rep {
            $rep.append-header: 'Strict-transport-security',
                "max-age=$!max-age"
        }
    }
}
```

### Request middleware that may produce a response

Often, it is desirable to write middleware that looks at an incoming request
and conditionally emits it for "normal" processing, or alternatively emits an
early response.

This requires two insertions into the pipeline: one to process the request,
and another to inject the early response, skipping over other pieces of the
pipeline. Implementing the `Cro::HTTP::Middleware::Conditional` role requires
writing a single method, `process`; the request and response parts of the
middleware are then constructed automatically.

The `process` method is passed a `Supply` of incoming requests. It should
return a `Supply` that, for each request received, will `emit` either:

* That request object, perhaps after some tweaks. The request object will
  continue onwards through the pipeline "as normal".
* A `Cro::HTTP::Response` object, which represents an early response. This
  will be forwarded to a later point in the pipeline, skipping over the usual
  request processing.

For example, to respond to incoming requests that are not from the loopback
interface with a 403 Forbidden response, one could write this:

```
class LocalOnly does Cro::HTTP::Middleware::Conditional {
    method process(Supply $requests) {
        supply whenever $requests -> $request {
            if $request.connection.peer-host eq '127.0.0.1' | '::1' {
                # It's local, so continue processing.
                emit $req;
            }
            else {
                # It's not, so emit a 403 forbidden response.
                emit Cro::HTTP::Response.new(:$request, :403status);
            }
        }
    }
}
```

This role does not implement `Cro::Transform`, since it actually is a way of
declaring a pair of transforms that work together with connection state. It
instead does the `Cro::HTTP::Middleware::Pair` role, described below.

### Middleware involving both requests and responses

The `Cro::HTTP::Middleware::RequestResponse` role is for middleware that needs
to take action for both the request and the response. This is both the most
flexible kind of middleware but also the trickest to write, since it will most
often involve some state that exists between requests and responses either on
the same or over many connections. Note that even on a single connection,
requests may be processed concurrently (particularly under HTTP/2.0). It is
therefore important to protect any state, perhaps by keeping it in a `monitor`
(use `OO::Monitors` for this).

A typical use for `Cro::HTTP::Middleware::RequestResponse` is implementing a
response cache. Here, incoming requets should first do a lookup in the cache
to see if the request can be satisfied from the cache; if so, the response is
sent from the cache. Otherwise, processing proceeds as normal, and in the
response middleware a cache entry is made. Note that this is a very minimal
response cache, that caches everything, forever, without regard to language,
encoding, and so forth. The cache is held per instance of the middleware, and
so lives between requests.

```
use Cro::HTTP::Request;
use Cro::HTTP::Response;
use OO::Monitors;

monitor CachedData {
    my class Entry {
        has $.status;
        has @.headers;
        has $.body-blob;
    }
    has Entry %!cache;

    method lookup(Cro::HTTP::Request $request) {
        with %!cache{$req.target} {
            my $resp = Cro::HTTP::Response.new: :$request, :status(.status);
            $resp.append-header($_) for .headers;
            $resp.set-body-byte-stream(supply emit .body-blob);
            return $resp;
        }
        return Nil;
    }

    method add($key, $status, @headers, $body-blob --> Nil) {
        %!cache{$key} = Entry.new: :$status, :@headers, :$body-blob;
    }
}

class ResponseCache does Cro::HTTP::Middleware::RequestResponse {
    has CachedData $!cache .= new;

    method process-requests(Supply $requests) {
        supply whenever $requests -> $req {
            with $!cache.lookup($req) -> $res {
                emit $res;
            }
            else {
                emit $req;
            }
        }
    }

    method process-responses(Supply $responses) {
        supply whenever $responses -> $res {
            my $key = $res.request.target;
            my $status = $res.status;
            my @headers = $res.header-list;
            whenever $res.body-blob -> $body-blob {
                # Produce the response, and cache the bytes, rather than
                # going through body serialization every time in the
                # future.
                $!cache.add($key, $status, @headers, $body-blob);
                $resp.set-body-byte-stream(supply emit $body-blob);
                emit $res;
            }
        }
    }
}
```

The `Cro::HTTP::Middleware::RequestResponse` role requires implementing the
`process-requests` and `process-responses` methods, which are passed `Supply`
instances containing a stream of requests and responses to process. The
`process-requests` method should return a `Supply` that, for each request
received, will `emit` either:

* That request object, perhaps after some tweaks. The request object will
  continue onwards through the pipeline "as normal".
* A `Cro::HTTP::Response` object, which represents an early response. This
  will be emitted as if it came after the response part of the middleware
  (and so will not be seen by `process-response`).

The `process-responses` method receives a `Supply` that will emit responses
to be processed. It must emit those responses after processing them.

This role does not implement `Cro::Transform`, since it actually is a way of
declaring a pair of transforms that work together with connection state. It
instead does the `Cro::HTTP::Middleware::Pair` role, described below.

## Cro::HTTP::Middleware::Pair

This role represents a pairing of HTTP request and response transforms, such
that they can be considered by the user to be a single piece of middleware.
This role is recognized and processed specially by:

* `Cro::HTTP::Server` in the `before` argument; it extracts the request part
  and inserts it at the location it is placed within the list of `before`
  middleware, and unshifts the response part onto the `after` middleware.
  This means any explicitly declared `after` middleware will process the
  output of the response middleware, and earlier `before` middleware will
  wrap around latter `before` middleware.
* `Cro::HTTP::Router` in the `before` function; it extracts the request part
  and calls `before` on it, and then extracts the response part and calls
  `after` on it.

The `Cro.compose(...)` method does not recognize `Cro::HTTP::Middleware::Pair`
but can still be used by calling `.request` and `.response` to get the two
parts, inserting them at the appropriate point in the pipeline.
