use Cro::Tools::Link::Editor;
use Test;

my $service1 = 't/tools-services-test-dir/service1/.cro.yml'.IO;
my $content1 = slurp $service1;
my $service2 = 't/tools-services-test-dir/nested/service2/.cro.yml'.IO;
my $content2 = slurp $service2;
my $current = $content1;

lives-ok { add-link('service1', 'service2', 'http') }, 'Can add link';
$current = slurp $service1;
like $current, /'links: ' \n/, 'Links section is filled';
like ($current), /'host-env: SERVICE2_HTTP_HOST'/, 'Host is added';
like ($current), /'port-env: SERVICE2_HTTP_PORT'/, 'Port is added';

lives-ok { rm-link('service1', 'service2', 'http') }, 'Can remove link';
$current = slurp $service1;
like   ($current), /'links:  []'/, 'Links section is empty';
unlike ($current), /'SERVICE2_HTTP_HOST'/, 'Host is removed';
unlike ($current), /'SERVICE2_HTTP_PORt'/, 'Port is removed';

# Restore state
spurt $service1, $content1;
spurt $service2, $content2;

done-testing;
