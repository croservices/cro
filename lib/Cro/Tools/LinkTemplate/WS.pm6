use Cro::Tools::LinkTemplate;

class Cro::Tools::LinkTemplate::WS does Cro::Tools::LinkTemplate {
    method protocol() { 'ws' }
    method generate(Str $service, Str $endpoint, (:$host-env!, :$port-env!)) {
        my $setup-variable = "\$$service-$endpoint";
        my $setup-code = q:c:to/CODE/;
        my {$setup-variable} = Cro::WebSocket::Client.connect('ws://%*ENV<{$host-env}>:%*ENV<{$port-env}>/start');
        CODE
        Cro::Tools::GeneratedLink.new(use => 'Cro::WebSocket::Client', :$setup-code, :$setup-variable)
    }
}
