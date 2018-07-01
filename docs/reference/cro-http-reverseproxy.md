# Cro::HTTP::ReverseProxy

A reverse proxy accepts incoming requests and delegates them to another HTTP
server, passing that server's response back to the client. A reverse proxy may
modify the request and/or response, and route different requests to different
target servers.

Potential applications of a HTTP reverse proxy include:

* Providing a common endpoint that delegates to multiple backend services
* Inserting extra headers (for example, mapping a session token from the
  browser into a JSON Web Token expected by backend services)
* Load-balancing requests over multiple backend services
* Aiding A/B testing by routing requests to partiuclar versions of a service
* Providing authenticated access to a non-authenticated service (assuming the
  non-authenticated service is not exposed directly)
* SSL termination
* Caching
* Content transformation

## Proxying all incoming requests

The class `Cro::HTTP::ReverseProxy` is a `Cro::Transform` that consumes a
`Cro::HTTP::Request` and produces a `Cro::HTTP::Response`. Therefore, it may
be used as the `application` parameter to `Cro::HTTP::Server`. This setup is
ideal if *all* the incoming requests should be proxied, since it avoids the
overhead of `Cro::HTTP::Router`.

First, set up the reverse proxy, specifying `to`, which is the target base URL
(that is, the incoming target will be appended to it):

```
my $proxy = Cro::HTTP::ReverseProxy.new:
    to => 'http://the.target.base/url/';
```

Then host it:

```
my $server = Cro::HTTP::Server.new:
    port => 10101,
    application => $proxy;
$server.start;
react whenever signal(SIGINT) {
    $server.stop;
}
```

## Proxying just some routes

Since `Cro::HTTP::ReverseProxy` is a `Cro::Transform` from HTTP requests to
HTTP responses, it may be used with `Cro::HTTP::Router`'s `delegate` function.
This is useful when wanting to directly handle *some* requests, while proxying
others.

```
my $app = route {
    get -> {
        content 'text/plain', 'Unproxied URL';
    }

    # /user/foo proxied to http://user-service/foo
    delegate <user *> => Cro::HTTP::ReverseProxy.new:
        to => 'http://user-service/';

    # /product/foo proxied to http://product-service/foo
    delegate <product *> => Cro::HTTP::ReverseProxy.new:
        to => 'http://product-service/';
}
```

## Proxying without appending the target URL

Sometimes, one might wish to proxy all requests to a single target URL, without
appending the target of the request. This is primarily useful in conjunction
with other features (such as manipulating the request). Instead of `to`, pass
`to-absolute`:

```
my $app = route {
    # Everything under /images/ proxied to a really cute cat picture
    # (provide your own, or there's just a few on the internet...)
    delegate <images *> => Cro::HTTP::ReverseProxy.new:
        to => 'http://really-cute.cat/picture.gif';
}
```

## Controlling the target URL

Sometimes, it's desirable to proxy different requests to different URLs. This
can be achieved by passing a `Code` object to `to` or `to-absolute`.

For example, picking two different servers to proxy to at random could be
achieved with:

```
my @servers = 'http://replica-a/', 'http://replica-b/';
my $proxy = Cro::HTTP::ReverseProxy.new:
    to => { @servers.pick };
```

The request object is passed in `to`, allowing the target to be determined
based upon request properties:

```
my $proxy = Cro::HTTP::ReverseProxy.new:
    to => {
        .has-header('authorization')
            ?? 'http://private-service/'
            !! 'http://public-service/'
    };
```

If doing significant amounts of work in the code block, for example doing a
database query, and if the proxy is to support HTTP/2.0 requests, then return
an `Awaitable` object (for example, a `Promise`) that will be completed with
the target URL. This avoids blocking processing of other HTTP/2.0 requests
multiplexed on the same client connection.

Everything works in the same way for `to-absolute`, except that the result
will be used as the absolute target URL.

## Transforming the request

To transform the request before it is proxied to the target, pass the code to
transform it using the `request` named argument. The code will be called with
the `Cro::HTTP::Request` object.

```
my $proxy = Cro::HTTP::ReverseProxy.new:
    to => 'http://the.target.base/url/',
    request => {
        .add-header('X-Experiment', <A B>.pick);
    };
```

If wishing to do something involving the network or some other time-consuming
operation, write this asynchronously to avoid blocking processing of HTTP/2.0
multiplexed requests:

```
my $proxy = Cro::HTTP::ReverseProxy.new:
    to => 'http://the.target.base/url/',
    request => -> $req {
        start {
            my $jwt = await jwt-lookup($req.cookie-value('session-id'));
            $req.add-header('Authorization', "Bearer $jwt");
        }
    };
```

It is also possible to obtain the request body and transform that, using
`set-body` to put in place the new request body.

```
my $asciify-proxy = Cro::HTTP::ReverseProxy.new:
    to => 'http://the.target.base/url/',
    request => -> $req {
        start {
            if $req.content-type.type-and-subtype eq 'application/json' {
                my $body = await $req.body-text;
                $req.set-body:
                    $body.subst(/<-[\x00..\x7F]>/, '?', :g);
            }
        }
    };
```

## Transforming the response

To transform the response from the target before it is returned to the client,
pass the code to transform it using the `response` named argument. The
`Cro::HTTP::Response` object will be passed to the code as an argument.

```
my $proxy = Cro::HTTP::ReverseProxy.new:
    to => 'http://the.target.base/url/',
    response => {
        .remove-header('server');
    };
```

If doing a long-running operation or transforming the body, then it is better
that the transform code works asynchronously. Any `Awaitable` returned will be
automatically awaited.

```
my $analytics-insertion-proxy = Cro::HTTP::ReverseProxy.new:
    to => 'http://the.target.base/url/',
    response => -> $res {
        start {
            if $res.content-type.type-and-subtype eq 'text/html' {
                my $body = await $res.body-text;
                $res.set-body:
                    $body.subst(/<?before '</body>'>/, $analytics-code);
            }
        }
    };
```

## Per-request state

Sometimes it's desirable to keep some state for each request that is being
proxied, and refer to it in the request, response, or dynamic `to` callbacks.
The `$*PROXY-STATE` dynamic variable is set up when each of the callbacks are
made, and can be assigned to and accessed as needed.

For example, an A/B testing proxy could be set up as follows:

```
my %experiments =>
    A => 'http://service-version-a/',
    B => 'http://service-version-b/';
my class ProxyState {
    has Str $.experiment is required;
}
my $proxy = Cro::HTTP::ReverseProxy.new:
    to => sub ($request) {
        my $exp;
        with $request.cookie-value('ab-experiment') {
            $exp = $_ if %experiments{$_}:exists;
        }
        $exp //= %experiments.keys.pick;
        $*PROXY-STATE = ProxyState.new(experiment => $exp);
        return %experiments{$exp};
    },
    response => {
        .set-cookie('ab-experiment', $*PROXY-STATE.experiment);
    };
```

## Thread safety

The callbacks passed to `Cro::HTTP::ReverseProxy` may be called on multiple
threads simultaneously. However, they are called one at a time for a given
request (so the `to` and `request` callbacks can never run at the same time
for a particular request), meaning that use of the per-request `$*PROXY-STATE`
is always safe.

If the proxy needs to deal with other state, then that state should be given
suitable protection (for example, by using `OO::Monitors` and placing it in a
`monitor`).
