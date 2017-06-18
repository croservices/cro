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
