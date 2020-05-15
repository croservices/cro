# Cro::HTTP::PushPromise

A `Cro::HTTP::PushPromise` is a subclass of `Cro::HTTP::Request`. In a server
context, it will be processed just like a request, the only difference being
that the "request" originated on the server as a result of a response having
one or more push promises. In a client context, it represents what was
promised, and provides asynchronous access to the response that fulfils the
push promise.

## Getting the promised response

The `response` method returns a Raku `Promise` that will be `Kept` with a
`Cro::HTTP::Response` object when the promised response is delivered. Should
that not be possible for some reason, then the `Promise` will be broken.

This will typically only be applicable in a client context, however the
`Promise` will be `Kept` in a server context also.

## Setting the promised response

The response can be set by calling the `set-response` method; this keeps the
`Promise` that has been, or will be, returned by `response`. Note that this
will typically only be done by Cro internals.
