use Cro::Tools::LinkTemplate;

class Cro::Tools::LinkTemplate::HTTPS does Cro::Tools::LinkTemplate {
    method protocol() { 'https' }
    method generate(Str $service, Str $endpoint, (:$host-env!, :$port-env!)) {
        my $setup-variable = "\$$service-$endpoint";
        my $setup-code = q:c:to/CODE/;
        constant %ca := { ca-file => 'secret-location/ca-crt.pem' };
        my {$setup-code} = Cro::HTTP::Client.new:
                       base-uri => "https://%*ENV<{$host-env}>:%*ENV<{$port-env}>/", :%ca;
        CODE
        Cro::Tools::GeneratedLink.new(use => 'Cro::HTTP::Client', :$setup-code, :$setup-variable)
    }
}
