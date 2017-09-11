# Cro::Tools::LinkTemplate

Link templates are used to generate code that sets up an inter-service link.
They are used when a `:link<...>` option is passed to `cro stub`, as well as
by the `cro link` subcommand.

## Implementing a link template

Link templates exist per protocol, the protocol being that specified in the
`protocol` key of an `endpoint` in a `.cro.yml` file. Link template modules
should live under the `Cro::Tools::LinkTemplate` package and must do the
`Cro::Tools::LinkTemplate` role. For example:

    class Cro::Tools::LinkTemplate::HTTP does Cro::Tools::LinkTemplate {
        ...
    }

The role requires that two methods be implemented. The `protocol` method is
the string name of the protocol that the template provides code for.

    method protocol() { 'http' }

The `generate` method generates code for the link. It should return an
instance of `Cro::Tools::GeneratedLink`, which has two required properties:

* `setup-code` - the code that creates an instance of some client object that
  will connect to the endpoint and allow interaction with it
* `setup-variable` - the variable that the `setup-code` populates (this should
  generally be derived from the target service and endpoint name)

And the optional property:

* `use` - one or more modules that `use` statements should be added for

For example:

    method generate(Str $service, Str $endpoint, (:$host-env!, :$port-env!)) {
        my $setup-variable = q:c/${$service}-{$endpoint}/;
        my $setup-code = q:c:to/CODE/;
            my {$var-name} = Cro::HTTP::Client.new:
                base-uri => "http://%*ENV<{$host-env}>:%*ENV{$host-port}/";
            CODE
        return Cro::Tools::GeneratedLink.new:
            use => 'Cro::HTTP::Client', :$setup-code, :$setup-variable
    }
