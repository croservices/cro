# Cro::WebSocket::Message

This class represents a message received over or to be sent over a web
socket. A message will either be parsed from, or serialized into, one
or more frames.

## Opcodes

The `Cro::WebSocket::Message::Opcode` enum contains the various kinds of
message:  `Text`, `Binary`, `Ping`, `Pong`, and `Close`. These are available
as just `Cro::WebSocket::Message::Close`, for example. The message level has
no Continuation opcode, because Message includes all frames' content already.
It can be used as follows:

    if $message.opcode ~~ Cro::WebSocket::Message::Close { ... }

# Attributes

## opcode

`opcode` attribute represents one of enum value, list of possible
values is described in `Opcodes` section.

## fragmented

`fragmented` attribute is a `Bool` flag that represents whether this
message fragmented or not. It is set automatically in case of special
`new` implementation usage or must be set to correct value during
instance creation.

`fragmented` is `True` if the Message consists of more than one
frame. It can be determined during serialization(if `body-byte-stream`
emits more than one value) or during Message parsing(if the first
Message frame is not final).

# Methods

## new

The class may be instantiated with "shortcut" `new` calls or in a
default way (specifying each attribute). Such constructors can take
`Blob`, `Str` and `Supply`, that can be used as follows:

    my $m1 = Cro::WebSocket::Message.new('Single-frame Message with a text string and Text opcode');
    my $m2 = Cro::WebSocket::Message.new('Single-frame Message with a Blob and Binary opcode'.encode);
    my $m3 = Cro::WebSocket::Message.new(supply { emit "Multi-frame message"; emit "With binary opcode"; });

In the case that a body serializer is being used, then any object that these
can handle may be passed.

Message instance can be also created as

    my $m = Cro::WebSocket::Message.new(opcode => Binary,
        fragmented => False, body-byte-stream => supply {
            emit 'Content'.encode('utf-8');
        });

## is-text

Returns `Bool` value `True` if the Message's `opcode` is `Text`.

## is-binary

Returns `Bool` value `True` if the Message's `opcode` is `Binary`.

## is-data

Returns `Bool` value `True` if the Message's `opcode` is `Text` or
`Binary`.

## body-byte-stream

`body-byte-stream` is a Supply that emits `Blob`s. It may be used to process
the payload of every frame as it arrives over the network, however in cases
where this streaming behavior is not required it is much more convenient to
use the `body-blob`, `body-text`, and `body` methods for access to the
message payload.

## body-text

Returns a Promise that will be kept on every frame's payload
collection finish. The `result` value of the Promise will be a `Str`
that contains the Message payload decoded as `UTF-8`.

## body-blob

Returns a Promise that will be kept on every frame's payload
collection finish. The `result` value of the Promise will be a `Buf`
that contains the Message payload.

## body

By default, this will be a `Str` for Text messages and a `Buf` for Binary
messages. However, if an alternate body parser/serializer has been set up,
then it might be some other object (for example, if a JSON body parser is
configured then it would be the `Hash` or `List` resulting from JSON parsing).
