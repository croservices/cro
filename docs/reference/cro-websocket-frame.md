# Cro::WebSocket::Frame

The `Cro::WebSocket::Frame` clas represents WebSocket frame as defined
per RFC 6455. The frame is assumed to be already `unmasked`/`masked`
on `parser`/`serializer` level.

It exports `Opcode` enum that consists of possible frame opcodes, they
are:

- Continuation - 0
- Text - 1
- Binary - 2
- Close - 8
- Ping - 9
- Pong - 10

It can be used with full name qualification as follows

    my $opcode = Cro::WebSocket::Frame::Opcode(0);

# Attributes

The class has three attributes, all of them are marked as `rw``;

## fin

`fin` class attribute is a `Bool` flag that indicates whether this
message final or not.

## opcode

`opcode` class attribute describes frame opcode.

## payload

`payload` is a `Blob` that contains Payload Data part of the frame.
Payload is treated as a single blob, i.e. there is no distinction
between Extension data and Application data on this level.
