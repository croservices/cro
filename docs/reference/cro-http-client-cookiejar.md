# Cro::HTTP::Client::CookieJar

A cookie jar is used to hold cookies set by HTTP responses, and add the
appropriate cookies to a HTTP request. It is designed for use in conjunction
with `Cro::HTTP::Client`; in many cases, this type need not be used directly.

## Adding cookies from a response into the jar

The `add-from-response` method is used to add the cookies from a
`Cro::HTTP::Response` into the cookie jar. In order to allow correct future
matching of the cookies, the request URI must also be included, in order to
determine the host, path, and if the request was secure (HTTPS). The URI
should be passed as an instance of `Cro::Uri`.

    $jar.add-from-response($resp, $uri);

## Adding cookies from the jar into a request

The `add-to-request` method is used to add cookies from the jar that match
the specified request URI into the provided request object. The request should
be an instance of `Cro::HTTP::Request` and the URI an instance of `Cro::Uri`.

    $jar.add-to-request($req, $uri);

## Introspecting the jar contents

To get a `List` of all cookies in the jar, use `contents`. This returns a
`List` of `Cro::HTTP::Cookie` objects.

    my @cookies = $jar.contents;

To get a `List` containing only those cookies that would match a particular
URI, pass that URI to the `contents` method.

    my @uri-cookies = $jar.contents($uri);

## Removing cookies from the jar

To remove all cookies from the jar, call `clear`.

    $jar.clear();

To remove all cookies matching a particular URI, pass that URI (it must be a
`Cro::Uri`):

    $jar.clear($uri);

To remove an individual cookie, pass the name of the cookie to clear also.

    $jar.clear($uri, $name);
