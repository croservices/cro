use Cro::Tools::LinkTemplate;

class Cro::Tools::LinkTemplate::HTTP does Cro::Tools::LinkTemplate {
    method protocol() { 'http' }
    method generate(Str $service, Str $endpoint, (:$host-env!, :$port-env!)) {
        my $setup-variable = "\$$service-$endpoint";
        my $setup-code = q:c:to/CODE/;
        my {$setup-variable} = Cro::HTTP::Client.new:
                       base-uri => "http://%*ENV<{$host-env}>:%*ENV<{$port-env}>/";
        CODE
        Cro::Tools::GeneratedLink.new(use => 'Cro::HTTP::Client', :$setup-code, :$setup-variable)
    }
}
