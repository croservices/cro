# Getting started with Cro

Here's a list of things to do to get Cro running on your machine.

## Install Raku

Cro services are written in Raku; if you have not yet installed a Raku
compiler, [see these instructions](https://raku.org/downloads/).

## Install Cro

Install Cro from the command line using `zef`:

```
zef install --/test cro
```

This includes the `cro` development tool, as well as the Cro core, HTTP, and
web sockets libraries.

## Write a Cro service

Copy the following code to a file called `hello.p6`:

```
use Cro::HTTP::Router;
use Cro::HTTP::Server;

my $application = route {
    get -> {
        content 'text/html', 'Hello Cro!';
    }
}

my Cro::Service $service = Cro::HTTP::Server.new:
    :host<localhost>, :port<10000>, :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}
```

## Run the Cro service

To start the service, just run the script from the command line:

```
raku hello.p6
```

## Check that the service runs ok

There should now be a page saying 'Hello Cro!' at http://localhost:10000

Congratulations, you have successfully installed Cro!

## Extra credit: use the cro development tool

The `cro stub` command generates stub services for you, to get started more
quickly and with better defaults. Here we use it to create a simple HTTP
service, with ID `hello` and in the `hello` directory:

```
cro stub http hello hello
```

The `cro run` command will start your service (and automatically restart the
service if you change a file):

```
cro run
```

You can change the service by editing files in the `hello/` subdirectory. The
HTTP routes, for example, are in `hello/lib/Routes.rakumod`.

## What next?

* Learn about routing URLs to handlers, working with query strings and request
  bodies, and producing responses using `Cro::HTTP::Router`
* Learn about using templates to produce responses using `Cro::WebApp::Template`
* Learn about [sessions and authentication](/docs/http-auth-and-sessions)
* Learn about writing WebSocket handlers using `Cro::HTTP::Router::WebSocket`
* Learn more about the [cro development tool](/docs/cro-tool) and the associated
  [.cro.yml file](/docs/cro-yml)
* Learn how to [structure larger services](/docs/structuring-services)
