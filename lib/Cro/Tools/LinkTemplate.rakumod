unit package Cro::Tools;

use File::Find;
use Cro::Tools::TemplateLocator;
use Cro::Tools::CroFile;

role GeneratedLink {
    has @.use;
    has Str $.setup-code is required;
    has Str $.setup-variable is required;
}

role LinkTemplate {
    method protocol(--> Str) { ... }

    method generate(Str $service, Str $endpoint, %options --> GeneratedLink) { ... }
}

our sub populate-links(@option-links, @generated-links, @links) is export {
    sub conk($message) {
        note $message;
        exit 1;
    }

    my @services = find(dir => $*CWD, name => / \.cro\.yml$/);
    my @link-templates = get-available-templates(Cro::Tools::LinkTemplate);

    for @option-links -> $link {
        my ($service, $endp) = $link.split(':');
        unless $service|$endp {
            conk "`$link` is incorrect link format; Use 'service:endpoint'.";
        }
        my $cro-file;
        for @services {
            my $file = Cro::Tools::CroFile.parse($_.IO.slurp);
            if $file.id eq $service && $file.endpoints.grep(*.id eq $endp) {
                $cro-file = $file; last;
            }
        }
        unless $cro-file {
            conk "There is no connection point to service $service with endpoint {$endp}.";
        }
        my $endpoint = $cro-file.endpoints.grep(*.id eq $endp).first;
        my $gl-template = @link-templates.grep(*.protocol eq $endpoint.protocol)[0];
        unless $gl-template ~~ Cro::Tools::LinkTemplate {
            conk "There is no link template for protocol {$endpoint.protocol}.";
        }
        my $generated = $gl-template.generate($service,    $endpoint.id,
                                              (host-env => $endpoint.host-env,
                                               port-env => $endpoint.port-env));
        @generated-links.push: $generated;

        @links.push: Cro::Tools::CroFile::Link.new(
            :$service, endpoint => $endpoint.id,
            host-env => $endpoint.host-env,
            port-env => $endpoint.port-env
        );
    }
}
