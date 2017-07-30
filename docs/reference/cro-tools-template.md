# Cro::Tools::Template

Templates are used by `cro stub` to generate a stub project. The `cro web` UI
uses them as the backend to its service stubbing UI also. A template does the
`Cro::Tools::Template` role. Templates are located by module name; any module
`Cro::Tools::Template::YourNameHere` or `CroX::Tools::Template::YourNameHere`
will be identified as a template provided that, when the module is loaded,
that symbol resolves to something doing the `Cro::Tools::Template` role.

## Basics

The `id` method must be implemented, returning an ID for the template that
will be used to identify it when used from the command line. This is a flat
namespace; consider picking a name that is unlikely to have conflicts.

The `name` method is a user-friendly name, presented in the web UI's list of
templates at at the command line when showing the list of available templates.

This is how they are implemented in the built-in HTTP service template, as an
example:

    method id(--> Str) { 'http' }
    method name(--> Str) { 'HTTP Service' }

## Options

Templates may be parameterized with one or more options, which are collected
from the user. In the web UI, they are collected by a a generated form. At the
command line tool:

* If the user doesn't specify any options as command line arguments, then they
  will be prompted for each one (with the ability to press enter to get the
  default, where applicable)
* If the user does specify options at the command line, it will be presumed
  they are providing all options that way, and missing options will be treated
  as an error.

Options are specified by implementing the `options` method, which is expected
to return a `List` of `Option` objects (this type is lexically exported as the
short name `Option` for convenience; `Cro::Tools::Template::Option` is its
fully qualified name). Each option needs:

* An `id` (used to identify it in the comamnd line options, and used to pass
  it back to your template)
* A `name` (used to present to the user when prompting for the option)
* A `type` (should be one of `Bool`, `Int`, or `Str`, or some `subset` type
  of these to perform stronger validation of the value)

It may also optionally have a `default`, which should be either an instance of
`type` (for example, `True` for a `Bool` option) or a `Callable` that will be
invoked with a hash of the provided so far (so the default can be picked in
terms of previous suggestions). Here is the `options` method for the built-in
HTTP template:

    method options(--> List) {
        Option.new(
            id => 'secure',
            name => 'Secure (HTTPS)',
            type => Bool,
            default => True
        ),
        Option.new(
            id => 'http1',
            name => 'Support HTTP/1.1',
            type => Bool,
            default => True
        ),
        Option.new(
            id => 'http2',
            name => 'Support HTTP/2.0',
            type => Bool,
            default => { .<secure> || !.<http1> }
        ),
        Option.new(
            id => 'websocket',
            name => 'Support Web Sockets',
            type => Bool,
            default => False
        )
    }

The method `get-option-errors` may optionally be implemented to perform
multi-option validation. It is expected to return an empty `List` when all is
well, or a `List` of `Str` errors to indicate issues. It is passed a hash of
the entered options. Here is the HTTP service template's implementation, as
an example (it destructures the options hash for conveneince):

    method get-option-errors((:$http1, :$http2, :$secure) --> List) { () }
        my @errors;
        unless $http1 || $http2 {
            push @errors, 'Must select at least one of HTTP/1.1 or HTTP/2.0';
        }
        if $http1 && $http2 && !$secure {
            push @errors, 'Can only support HTTP/1.1 and HTTP/2.0 with HTTPS';
        }
        return @errors;
    }

## Generation

The `generate` method must be implemented to provide the logic that generates
the stub:

    method generate(IO::Path $where, Str $id, Str $name, %options) { ... }

The argumnets are:

* The path where the service should be generated
* The ID and name of the service, which should be placed into the generated
  `.cro.yml` file
* The options that were provided

It is left to the template to decide what to do. However, it's generally
expected that a template will:

1. Write source files, including an entry point script, such that a working,
   barebones service can be successfully started
2. Optionally write any artefacts that would aid deployment, such as a
   `Dockerfile`.
3. Write a `.cro.yml` file. Use `Cro::Tools::CroFile` to generate this, rather
   rather than writing the YAML directly. It is strongly recommended to do
   this as the *final* step, so that when the service auto-runner picks up on
   the new `.cro.yml` file and tires to run the entrypoint script everything
   will be in place.
