use Cro::HTTP::Client;
use Cro::Tools::CroFile;
use Cro::Tools::Runner;
use Cro::Tools::Services;
use Shell::Command;
use Test;

sub with-test-dir(&test-case) {
    my $temp-dir = "$*TMPDIR/cro-test-{(0..9).roll(40).join}";
    mkdir $temp-dir;
    cp 't/tools-services-test-dir', $temp-dir, :r;
    LEAVE rm_rf $temp-dir;
    test-case($temp-dir);
}

with-test-dir -> $test-dir {
    my $r = Cro::Tools::Runner.new(
        services => Cro::Tools::Services.new(base-path => $test-dir.IO),
        service-id-filter => 'service1'
    );
    my $messages = $r.run.Channel;

    my $started = $messages.receive;
    isa-ok $started, Cro::Tools::Runner::Started,
        'Got started event';
    is $started.service-id, 'service1', 'Correct service ID was started';
    isa-ok $started.cro-file, Cro::Tools::CroFile, 'Have the Cro file object';
    is $started.endpoint-ports.elems, 1, 'Endpoint was assigned a port';
    ok $started.endpoint-ports<http>:exists, 'HTTP endpoing exists in ports';
    my $port = $started.endpoint-ports<http>;
    isa-ok $port, Int, 'Port number available as an Int';

    my $got-body;
    for ^10 -> $i {
        sleep 1;
        my $got = await Cro::HTTP::Client.get("http://localhost:$port/");
        $got-body = await $got.body-text;
        last;
        CATCH {
            default {
                diag "Check service up attempt {$i+1}: $_";
            }
        }
    }
    ok $got-body.defined, 'Could call the started service';
    is $got-body, 'Service 1 OK', 'Got expected resposne from service';
}

done-testing;
