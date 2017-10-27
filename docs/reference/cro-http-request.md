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

## Cookies

Cookies in a request are placed in a single `Cookie` header. This is somewhat
inconvenient to work with, and so `Cro::HTTP::Request` provides higher level
methods for working with cookies also.

### Accessing cookies

The `has-cookie($name)` method checks if there is a cookie with the specified
name. The name is matched case-sensitively. If there is a cookie with this
name, `True` is returned; otherwise, `False` is returned.

The `cookie-value($name)` method retrieves the value of the cookie with
specified name, matched case-sensitively. If there is no cookie with this
name, `Nil` is returned.

The `cookie-hash` method returns a `Hash` mapping cookie names to cookie
values. Note that mutation of the returned hash has no affect upon the
`Cro::HTTP::Request` object.

### Manipulating cookies

The `add-cookie` method has two multi candidates:

* `set-cookie(Cro::HTTP::Cookie)` - adds or updates any existing `Cookie`
  header line to include the cookie name and value specified in the
  `Cro::HTTP::Cookie` instance. If there is already a cookie with that
  name in the `Cookie` header value, it will be replaced with the new value.
* `add-cookie(Str $name, Str() $value)` - creates a `Cro::HTTP::Cookie`
  instance from specified name and value (to ensure they do not contain any
  disallowed characters), and delegate to the first `add-cookie` candidate

The `remove-cookie($name)` method removes the cookie with the specified name
from the `Cookie` header, provided such a cookie exists. It returns `True` if
a cookie was actually removed, and `False` otherwise.

## Stringification

Calling the `Str` method on a `Cro::HTTP::Request` will serialize the request
line and headers, giving the `HTTP/1.*` wire representation of the message
but excluding the body.
