# Cro::HTTP::Response

The `Cro::HTTP::Response` class does the `Cro::HTTP::Message` role, which
provides methods for working with headers and the request body. This class
adds functionality specific to HTTP responses.

## Status code

The `status` property is used to get and set the HTTP response status code.
It is constrained to hold a 3-digit integer value in the range 100..599.

## Stringification

Calling the `Str` method on a `Cro::HTTP::Response` will serialize the status
line and headers, giving the `HTTP/1.*` wire representation of the message
but excluding the body.

## Push promises (server side)

The `add-push-promise` method adds a `Cro::HTTP::PushPromise` to the response.
Mutiple push promises may be added. Provided the response is handled by the
HTTP/2.0 response serializer, push promise frames will be sent to the client,
and the `Cro::HTTP::PushPromise` will be sent to the HTTP/2.0 request parser,
which will emit it as if it were an incoming request.

The `close-push-promises` method indicates that no more push promises may be
added beyond this point. It is typically called by the response serializer,
and ordinary Cro users will have no need to call it.

The `push-promises` method returns a `Supply` that will `emit` each of the
added push promises, and be `done` provided `close-push-promises` was called.

## Push promises (client side)

The `push-promises` method returns a `Supply` that emits any push promises
that are sent by the remote server. Each will be emitted as an instance of
`Cro::HTTP::PushPromise`. One no further push promises may arrive, the
`Supply` will be `done`. In the event this method is called on a response
that is not using `HTTP/2.0`, then returned `Supply` will be `done`
immediately.

Internally, the `add-push-promise` and `close-push-promises` methods are used
by the HTTP/2.0 response parser to set up the responses. Put another way, the
client and server side of push promises share an API, with opposite parts of
it considered internal and external depending which side one is on.
