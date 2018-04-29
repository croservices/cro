# Cro::Uri

The `Cro::Uri` class supports working with Uniform Resource Identifiers, as
specified in RFC 3986. A `Cro::Uri` instance is immutable.

## Parsing methods

There are a number of methods that parse a string into a `Cro::Uri` instance.
They may all be called on the `Cro::Uri` type object.

### parse

Takes a string and attempts to parse it as an absolute URI.

    Cro::Uri.parse("http://example.com");

By default this method uses an internal parser and action class that acts
according to RFC 3986, however different parsers may be specified as a
named parameter:

    Cro::Uri.parse("http://example.com",
                   grammar => $custom-grammar,
                   actions => $custom-actions);

In case of parsing failure, the `X::Cro::Uri::ParseError` exception will be
thrown. This exception has `uri-string` field that contains the erroneous
string.

### parse-relative

Takes a string and tries to parse it as a relative URI. Functions like `parse`
in terms of customization and error handling.

### parse-ref

Takes a string and parses it as a URI reference (that is, either an absolute
or a relative URI). Functions like `parse` in terms of customization and error
handling.

## Getting URI parts

### schema

Returns the schema of the URI. For example, given `http://example.com/`, it
will return `http`. For a relative URI, this will return a type object.

### authority

Gets the authority part of the URI, if it has one. For example, given
`http://foo@bar.com:42/baz`, it would return `foo@bar.com:42`. If not present,
returns a type object.

### userinfo

Gets the userinfo part of the authority, if it has one. For example, given
`http://foo@bar.com:42/baz`, it would return `foo`. If not present, returns a
type object.

### user

Gets the user part of `userinfo`, if present. Decodes any percent escape
sequences.

### password

Gets the password part of `userinfo`, if present. (Note that use of this is
deprecated by the URI specification. The functionality is provided here for
the convenience of those who need to work with such URIs, and will remain in
Cro for the foreseeable future.) Decodes any percent escape sequences.

### host

Returns the host part of the authority, if it has one. For example, given
`http://foo@bar.com:42/baz`, it would return `bar`. If not present, returns a
type object. Any percent escape sequences in the host name will be decoded.

### host-class

Provided there is a host, returns its class. This is returned as a member of
the `Cro::Uri::Host` enumeration, which is defined as:

```
enum Cro::Uri::Host <RegName IPv4 IPv6 IPvFuture>;
```

If not present, returns a type object.

### port

Returns the `port` part of the authority, if present. For example, given
`http://foo@bar.com:42/baz` it would return 42.

### path

Returns the path part of the URI. URIs with an empty path part will return the
empty string. No percent decoding is performed by this method. For example,
given `http://foo@bar.com:42/baz/oh%20wow`, it would return `/baz/oh%20wow`.

### path-segments

Returns a list of URI decoded path segments. Sequences outside of the ASCII
range will be decoded as UTF-8. Given `http://foo@bar.com:42/baz/oh%20wow`,
this method would return the list `('baz', 'oh wow')`.

### query

Returns the query string part of the URI. For example, given
`http://bar.com:42/baz?x=1&y=2`, it would return `x=1&y=2`. No perecent
sequence decoding is performed. (For parsing of the query string as it is used
in HTTP applications, use `Cro::Uri::HTTP`, which adds this functionality).

### fragment

Returns the fragment part of the URI. For example, giveni
`http://bar.com/baz#abc`, it would return `abc`.

## Stringifying a URI

The `Str` method turns the URI back into a `Str`.

## Resolving relative URIs

The `add` method implements resolution of a relative URI, taking the `Cro::Uri`
instance it is called on as the base. It may be called with either a string,
which will be parsed as a URI reference, or another `Cro::Uri` object. Returns
a new `Cro::Uri` instance representing the result of the resolution. Any `.`
and `..` sequences will be processed as part of the resolution.

```
my $base = Cro::Uri.parse('http://foo.com/bar/baz/wat.html');
say ~$base.add('../eek.html');  # http://foo.com/bar/eek.html
```

## Percent decoding

The `decode-percents` subroutine takes a string and returns a new string,
where all percent escape sequences are converted to Unicode characters
(assuming UTF-8 decoding).

This subroutine is not exported by default, but can be obtained by using the
`decode-percents` tag:

```
use Cro::Uri :decode-percents;
```
