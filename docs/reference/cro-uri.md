# Cro::Uri

The `Cro::Uri` class abstracts Uniform Resource Identifier(Uri) in Cro
applications, according to RFC 3986.

It contains an internal grammar, that parses Uri, and a set of methods
to call on the client side.

# Methods

## parse

Method `parse` can be used on type object and is called with a string:

    Cro::Uri.parse("http://example.com");

By default this method uses internal parser and action class that acts
according to RFC 3986, however different parsers may be specified as a
named parameters:

    Cro::Uri.parse("http://example.com",
                   grammar => $custom-grammar,
                   actions => $custom-actions);

In case of parsing failure `X::Cro::Uri::ParseError` exception will be
thrown. This exception has `uri-string` field that contains an
erroneous string.

## user

Method retrieves value of `user` part of Uri. In case if name was not
specified, `Str` type object returns.

## password

Method retrieves value of `password` part of Uri. In case if name was
not specified or the method was called on , `Str` type object returns.
erroneous
## path-segments

Method returns a list of path segments. For every path segment Unicode
escape sequences will be resolved into actual characters using
`decode-percents` subroutine. If leading `/` is present, it will be
discarded in the resulting list.

## Str

Method will return a string that was used to create `Cro::Uri`
instance.

# Subroutines

## decode-percents

`decode-percents` subroutine takes a string and returns a new string,
where all Unicode escape sequences are converted to proper Unicode
characters.
