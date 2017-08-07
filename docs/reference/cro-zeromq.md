# Cro::ZeroMQ

This module enables building Cro pipelines using [ZeroMQ](http://zeromq.org/).
The lower-level components are intended to be composed together using
`Cro.compose`. Some higher level classes also exist to form Cro services and
clients in a more convenient way for the most common use cases. This document
assumes the reader has some existing understanding of ZeroMQ and its various
socket types.

## Cro::ZeroMQ::Message

This class represents a ZeroMQ message. It does the `Cro::Message` role. A
`Cro::ZeroMQ::Message` can represent both a message that was received and a
message to be sent (in a simple echo server, for example, it would be both).

ZeroMQ messages may consist of multiple parts. The `parts` method returns
an `List` of the parts that were receivered (or, if this is a message to be
sent, the parts added to send so far). Each part is represented as a `Blob`.
Since a `List` is returned, this cannot be mutated. The `body-blob` method
returns the last part, assuming that previous parts are some form of envelope.
This is only a convention provided by Cro. The `body-text` property will try
to decode `body-blob` as UTF-8; pass the `:enc` parameter to choose another
encoding.

The most basic way to construct a message to to pass an list of `Blob`s to the
`new` method:

    Cro::ZeroMQ::Message.new(
        parts => ($blob-key, $blob-message)
    )

There are also a number of convenience constructors taking a single positional
parameter that is either a string or a blob:

    Cro::ZeroMQ::Message.new("hello world")
    Cro::ZeroMQ::Message.new("goodbye cruel world".encode("ascii"))

As well as a slurpy candidate for multi-part messages:

    Cro::ZeroMQ::Message.new("SomeEventName", $event-json)

Whenever a `Str` is passed, it will first be encoded using UTF-8 before being
stored. (This is true of both the `Str` constructor and the slurpy positional
constructor; the constructor taking the `parts` named attribute expects only
`Blob`s.)

A `Cro::ZeroMQ::Message` is immutable once constructed.

Note that there is no way to provide or obtain a `Supply` of parts because
ZeroMQ doesn't send parts until it has seen them all, and doesn't pass parts
on to the application until it has received them all. Therefore, there's no
opportunity for increased performance by sending some parts earlier.

## Pipeline Components

Pipeline components exist each of the ZeroMQ socket types. They all may be
constructed with either (but not both of):

* `connect`, which specifies what to connect to. This may be an `Iterable` if
  the socket should be connected to multiple endpoints; otherwise, it will be
  treated as a single endpoint. The provided value(s) will be coerced to `Str`
  and should be of the form `tcp://somehost:5555`.
* `bind`, which specifies what to bind to. This may be an `Iterable` if the
  socket should be bound to multiple endpoints; otherwise it will be treated
  as a single endpoint. The provided value(s) will be coerced to `Str` and
  should be of the form `tcp://localhost:5555` (or `tcp:://*:5555` to bind to
  all interfaces).

Passing neither of `connect` or `bind`, or passing both of `connect` and
`bind`, will result in an exception of type `X::Cro::ZeroMQ::IllegalBind`.

The optional `high-water-mark` named parameter sets the high water mark (how
many messages may be outstanding for the socket enters an exception state,
either starting to block on send or drop messages, depending on the socket
type).

All of the ZeroMQ pipeline components do the `Cro::ZeroMQ::Component` role,
which factors out these commonalities. There will be little reason for typical
Cro applications to care about this, however.

### Cro::ZeroMQ::Push

This class is a `Cro::Sink` backed by a ZeroMQ PUSH socket. It is to be placed
at the end of a pipeline, consuming `Cro::ZeroMQ::Message` objects and sending
them.

### Cro::ZeroMQ::Pull

This class is a `Cro::Source` backed by a ZeroMQ PULL socket. It is to be
placed at the start of a pipeline, and produces `Cro::ZeroMQ::Message`
objects.

### Cro::ZeroMQ::Pub

This class is a `Cro::Sink` backed by a ZeroMQ PUB socket. It consumes
`Cro::ZeroMQ::Message` objects and publishes them.

### Cro::ZeroMQ::Sub

This class is a `Cro::Source` backed by a ZeroMQ SUB socket. It produces
`Cro::ZeroMQ::Message` objects for each message received. Subscriptions are
filtered on message prefix (only the first message part being considered as
the subscription key).

The `subscribe` named argument is **required** (since not subscribing will
always result in receiving no messages). It may take:

* A `Blob` specifying the subscription topic.
* A `Str` specifying the subscription topic; since they are matched as bytes,
  this will be encoded as `UTF-8`.
* An `Iterable` of subscription topics (will be iterated over and treated as
  `Blob` or `Str` would be)
* A `Whatever` (that is, `subscribe => *`), which is equivalent to calling
  `subscribe` with the empty `Blob` or empty `Str` and subscribes to all
  messages.
* A `Supply`, which will be tapped. Each emitted value will be treated as a
  subscription to establish, and may be a `Blob` or a `Str`. This allows the
  set of subscriptions to change dynamically over time.

Optionally, `unsubscribe` may be passed. This only takes a `Supply`, and each
time a topic is emitted (either as a `Blob` or a `Str`) an unsubscription will
take place. Note that it only makes sense to unsubscribe from topics that were
already subscribed to, and so this likely only makes sense in combination with
having passed a `Supply` to the `subscribe` named argument.

If the same topic is subscribed to multiple times, then an unsubscription will
only remove one of these (put another way, the set of topics subscribed to
behave as if they were reference counted). This behavior is provided by ZeroMQ
rather than added by Cro. Note that unsubscriptions must match a subscription
that is still active to be meaningful; it is not, therefore, possible to
subscribe to everything and then exclude things. (At the end of the day, these
are all just convenient ways to have `zmq_setsockopt` called.)

### Cro::ZeroMQ::XPub

This is a `Cro::Source` backed by a ZeroMQ XPUB socket. It produces
`Cro::ZeroMQ::Message` objects, which represent subscription requests. It is
`Cro::Replyable`, the replier being a `Cro::Sink` that consumes
`Cro::ZeroMQ::Message` objects (which correspond to messages to publish).
Typically used together with `Cro::ZeroMQ::XSub`.

### Cro::ZeroMQ::XSub

This is a `Cro::Source` backed by a ZeroMQ XSUB socket. It produces
`Cro::ZeroMQ::Message` objects, which represent messages received from
subscriptions. It is a `Cro::Replyable`, the replier being a `Cro::Sink`
that consumes `Cro::ZeroMQ::Message` objects (which represent subscription
requests to pass on to the publisher). Typically used together with
`Cro::ZeroMQ::XPub`.

### Cro::ZeroMQ::Rep

This class is a `Cro::Source` backed by a ZeroMQ REP socket, which produces
`Cro::ZeroMQ::Message`. It is also a `Cro::Replyable`, and the replier is a
`Cro::Sink` that sends a `Cro::ZeroMQ::Message` reply. Therefore, an echo
server would just be:

    my Cro::Service $echo = Cro.compose(
        Cro::ZeroMQ::Rep.new(bind => "tcp://*:5555")
    );

A more useful service would place one or more `Cro::Transform`s into the
pipeline to transform the request into a response. A ZeroMQ REP processes a
message at a time, so another message will not be emitted until the reply
has been sent by the replier. To build services that can work on multiple
messages asynchronously, `Cro::ZeroMQ::Router` is a better bet.

### Cro::ZeroMQ::Req

This class is a `Cro::Connector` backed by a ZeroMQ REQ socket. It consumes
`Cro::ZeroMQ::Message` and produces `Cro::ZeroMQ::Message`. It must never have
a message emitted to it while it is still waiting for the response from an
earlier message, to follow the ZeroMQ REQ constraints. To build clients that
can have multiple outstanding requests, `Cro::ZeroMQ::Dealer` is a better bet.

### Cro::ZeroMQ::Router

This class is a `Cro::Source` backed by a ZeroMQ ROUTER socket. It produces
`Cro::ZeroMQ::Message` objects. It is also a `Cro::Replyable`, the replier
being a sink that sends on the ROUTER socket.

### Cro::ZeroMQ::Dealer

This class is a `Cro::Connector` backed by a ZeroMQ DEALER socket. It consumes
and produces `Cro::ZeroMQ::Message` objects.

## Higher Level APIs

TODO
