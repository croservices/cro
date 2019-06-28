# Cro::MediaType

The `Cro::MediaType` class provides a range of functionality relating to media
types, including parsing them into their parts or serializing them from their
parts.

## Parsing a media type

To parse a media type, pass it to the `parse` method:

```
my $media-type = Cro::MediaType.parse('content/html; charset=UTF-8');
```

This results a `Cro::MediaType` instance.

## Extracting parts of the media type

Consider an example media type `application/vnd.foobar+json; charset=UTF-8`.
The following methods are available for extracting parts of the media type:

* `type` - returns `application`
* `subtype` - returns `vnd.foobar+json`
* `tree` - returns `vnd`
* `subtype-name` - returns `foobar`
* `suffix` - returns `json`
* `type-and-subtype` - returns `application/vnd.foobar+json`
* `parameters` - returns an `Array` containing a `Pair`; in the example
  given, `charset => 'UTF-8'`

## Constructing a media type from parts

The `new` method can be called to construct a media type from its parts. The
`type` and `subtype-name` named parameters are required; `tree`, `suffix`, and
`parameters` may be optionally provided.

## Serializing a media type

Stringify a `Cro::MediaType` object to turn it into a string representation of
the media type.

```
my $media-type = Cro::MediaType.new:
    type => 'application',
    tree => 'vnd',
    subtype-name => 'foobar',
    suffix => 'json',
    parameters => [charset => 'UTF-8'];

say ~$media-type;   # application/vnd.foobar+json; charset=UTF-8
```
