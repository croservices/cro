# Cro::HTTP::Cookie

The `Cro::HTTP::Cookie` class represents a cookie, as defined in RFC 6265. In
the context of a response or a useragent, all fields are relevant. In the
context of a request being sent to a server, only the name and value have any
significance, and the rest of the fields will be disregarded.

## Properties

The `Cro::HTTP::Cookie` class has the following properties, which are all
read only. They can all be passed in the constructor (`new`) or, to get a
modified version of an existing instance, passed to `clone`.

* `name` - the cookie name; constrained to only contain the characters
  allowed in `cookie-name` per RFC 6265 (required)
* `value` - the cookie value; constrained to only contain the characters
  in the range specified in `cookie-octet` in RFC 6265 (required)
* `expires` - the expiration time of the cookie, specified as a Perl 6
  `DateTime`
* `max-age` - the maximum age of the cookie in seconds, specified as a Perl 6
  `Duration` (in the constructor any `Real` may be passed; fractional parts
  will be rounded)
* `domain` - the domain the cookie is restricted to, if any; specified as a
  `Str` constrained per RFC 6265
* `path` - the path the cookie is restricted to, if any; specified as a `Str`
  constrained per RFC 6265
* `secure` - whether the cookie is only to be sent on a secure connection;
  a `Bool`
* `http-only` - whether the cookie should only be sent in HTTP requests, and
  so hidden from, for example, JavaScript running on the page; a `Bool`

## Methods

The `to-set-cookie()` method serializes the `Cro::HTTP::Cookie` instance
into a value to be set as a `Set-cookie` header. The `to-cookie()` method
serializes the cookie into the form `name=value` for inclusion in a `Cookie`
header.

The method `from-set-cookie` method, to be called on the `Cro::HTTP::Cookie`
type object, parses the value of a `Set-cookie` header and, provided the
parse was successful, returns a `Cro::HTTP::Cookie` instance representing the
parsed data. If it cannot be parsed per the syntax in RFC 6265, then an error
will be thrown. Extensions (`extension-av` in RFC 6265) are permitted but will
be ignored.
