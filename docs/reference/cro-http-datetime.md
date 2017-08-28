# Cro::HTTP::DateTime

Additional sub-module that provides a set of helpers for dealing with
date and time in different formats.  It mostly works with standard
DateTime class.

## DateTime parsing

Module exports `HTTP-date` regular expression, using which string with
date and time in three different formats can be parsed.

These formats are: `rfc1123`, `rfc850` and `asctime`, all of them are
described in RFC 2616.

This regular expression should be used only for string checking and
all conversion to DateTime should be done using `DateTimeGrammar`
grammar and `DateTimeActions` class in this manner:

    my $str = Sun, '06 Nov 1994 08:49:37 GMT';
    my DateTime $time = DateTimeGrammar.parse(, actions => DateTimeActions.new).made;

## DateTime Formatting

For formatting a DateTime object to supporting HTTP format, routine
`rfc1123-formatter` can be used. It takes a DateTime objects and
returns a `Str`. Other supported for parsing formats, such as `RFC
850` date and time format were marked as obsolete and hence not
provided.
