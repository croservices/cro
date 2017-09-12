unit package Cro::Tools;

role GeneratedLink {
    has @.use;
    has Str $.setup-code is required;
    has Str $.setup-variable is required;
}

role LinkTemplate {
    method protocol(--> Str) { ... }

    method generate(Str $service, Str $endpoint, %options --> GeneratedLink) { ... }
}

class Cro::Tools::LinkTemplate::HTTP does Cro::Tools::LinkTemplate {
    method protocol() { 'http' }
    method generate(Str $service, Str $endpoint, (:$host-env!, :$port-env!)) {
        my $setup-variable = "\$$service-$endpoint";
        my $setup-code = q:c:to/CODE/;
            my $client = Cro::HTTP::Client.new:
                         base-uri => "http://%*ENV<{$host-env}:%*ENV<{$host-port}>/";
        CODE
        Cro::Tools::GeneratedLink.new(use => 'Cro::HTTP::Client', :$setup-code, :$setup-variable)
    }
}
