# Cro::HTTP::Request

The `Cro::HTTP::Request` class does the `Cro::HTTP::Message` role, which
provides methods for working with headers and the request body. This class
adds functionality specific to HTTP requests.

## Request method and target

The `method` property can be used to get or set the HTTP request method (such
as `GET` or `POST`). The `target` property can be used to get or set the
request target. This typically contains a path and optionally a query string
part.

Working directly with the target is usually not convenient, so there are a
range of methods for accessing it. These read-only methods include:

* `path`, which gets the path part of the target without performing any kind
  of decoding
* `path-segments`, which gets a `List` of the path segments (for `/foo/bar`
  it would give a list `'foo', 'bar'`) and decodes any `%` escapes
* `query`, which gets the query part of the target without performing any
  kind of decoding
* `query-hash`, which gets a `Hash` mapping keys in the query string to
  values; if there are multiple values for a key, `Cro::HTTP::MultiValue` is
  returned (which inherits from `List` but stringifies to the values comma
  separated)
* `query-value($key)` - looks up a value in the `query-hash`

## Stringification

Calling the `Str` method on a `Cro::HTTP::Request` will serialize the requeset
line and headers, giving the `HTTP/1.*` wire representation of the message
but excluding the body.
