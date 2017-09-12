# Getting started with Cro

Here's a list of things to do to get Cro running on your machine.

## Install Perl 6

Cro runs in Perl 6, which can be downloaded at https://perl6.org/downloads/

When you install Perl 6, the `zef` module manager is also installed.

## Install Cro

Install Cro from the command line using `zef`:

```
zef install --/test cro
```

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

## Run the Cro program

To start the service, just run the script from the command line:

```
perl6 hello.p6
```

## Check that the service runs ok

There should now be a page saying 'Hello Cro!' at http://localhost:10000

Congratulations, you have successfully installed Cro!

Now learn more about building a simple HTTP application here: 
[Creating HTTP Services](intro/http-server).


## Extra credit: use `cro stub` and `cro run`

[Note: this part needs more testing...]

The `cro stub` command generates files and reasonable defaults for you in your current directory.
Here we use it to create a simple HTTP service:

```
cro stub http hello hello
```

The `cro run` command will start your service (and automatically restart the service if you change a file):

```
cro run
```
You can change the service by editing files in the `hello/` subdirectory, for example `hello/service.p6`
