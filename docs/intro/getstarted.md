# Getting started with Cro

Here's a list of things to do to get Cro running on your machine.

## Install Perl 6

Cro services are written in Perl 6; if you have not yet installed that,
[see these instructions](https://perl6.org/downloads/). Note that you will
need a fairly modern Perl 6; the ones included in packages can be very old.

Provided you install Perl 6 using Rakudo Star, the `zef` module manager will
also be installed.

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
perl6 hello.p6
```

## Check that the service runs ok

There should now be a page saying 'Hello Cro!' at http://localhost:10000

Congratulations, you have successfully installed Cro!

Now learn more about [building an HTTP service](http-server).

## Extra credit: use `cro stub` and `cro run`

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
HTTP routes, for example, are in `hello/lib/Routes.pm6`.
