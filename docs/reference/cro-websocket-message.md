# Cro::WebSocket::Message

This class represents a message received over or to be sent over a web
socket. A message will either be parsed from, or serialized into, one
or more frames.

## Opcodes

This class exports `Opcode` enum that may be used during Message
processing. Available values are: `Text`, `Binary`, `Ping`, `Pong`,
`Close`. Opcode of Continuation is not present, because Message
includes all frames' content already. It can be used as follows:

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

## body-byte-stream

`body-byte-stream` is a Supply that emits `Blob`s. It may be used to
process Payload of every frame in distinct manner, however it is much
more convenient to use `body-blob` or `body-text` methods for an
access to the Message payload.

# Methods

## new

The class may be instantiated with "short-cut" `new` calls or in a
default way(specifying each attribute). Such constructors can take
`Blob`, `Str` and `Supply`, that can be used as follows:

    my $m1 = Cro::WebSocket::Message.new('Single-frame Message with a text string and Text opcode');
    my $m2 = Cro::WebSocket::Message.new('Single-frame Message with a Blob and Binary opcode'.encode);
    my $m3 = Cro::WebSocket::Message.new(supply { emit "Multi-frame message"; emit "With binary opcode"; });

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

## body-text

Returns a Promise that will be kept on every frame's payload
collection finish. The `result` value of the Promise will be a `Str`
that contains all Message payload decoded as `UTF-8`.

## body-blob

Returns a Promise that will be kept on every frame's payload
collection finish. The `result` value of the Promise will be a `Buf`
that contains all Message payload.
