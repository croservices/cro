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

sub test-request($url) {
    my $got-body;
    for ^40 -> $i {
        sleep 1;
        my $request = Cro::HTTP::Client.get($url);
        await Promise.anyof($request, Promise.in(5));
        die "Timed out after 10s" unless $request;
        my $got = await $request;
        $got-body = await $got.body-text;
        last;
        CATCH {
            default {
                diag "Check service up attempt {$i+1}: $_";
            }
        }
    }
    return $got-body;
}

with-test-dir -> $test-dir {
    my $r = Cro::Tools::Runner.new(
        services => Cro::Tools::Services.new(base-path => $test-dir.IO),
        service-id-filter => 'service1'
    );
    my $start-restart-messages = Channel.new;
    my $other-messages = Channel.new;
    my $run-tap = $r.run.tap:
        {
            .isa(Cro::Tools::Runner::Started) || .isa(Cro::Tools::Runner::Restarted)
                ?? $start-restart-messages.send($_)
                !! $other-messages.send($_)
        },
        done => { $start-restart-messages.close() },
        quit => { $start-restart-messages.fail($_) };

    my $started = $start-restart-messages.receive;
    isa-ok $started, Cro::Tools::Runner::Started,
        'Got started event';
    is $started.service-id, 'service1', 'Correct service ID was started';
    isa-ok $started.cro-file, Cro::Tools::CroFile, 'Have the Cro file object';
    is $started.endpoint-ports.elems, 1, 'Endpoint was assigned a port';
    ok $started.endpoint-ports<http>:exists, 'HTTP endpoing exists in ports';
    my $port = $started.endpoint-ports<http>;
    isa-ok $port, Int, 'Port number available as an Int';

    my $got-body = test-request("http://localhost:$port/");
    ok $got-body.defined, 'Could call the started service';
    is $got-body, 'Service 1 OK', 'Got expected resposne from service';

    my $log = $other-messages.receive;
    isa-ok $log, Cro::Tools::Runner::Output, 'Got an output message after request';
    nok $log.on-stderr, 'Was not on STDERR';
    ok $log.line ~~ /200/, 'Got log line mentioning status code';

    my $service-file = "$test-dir/service1/service.p6";
    spurt $service-file, slurp($service-file).subst("OK", "UPDATED");
    my $restarted = $start-restart-messages.receive;
    isa-ok $restarted, Cro::Tools::Runner::Restarted,
        'Got restarted message';
    is $started.service-id, 'service1', 'Correct service ID was restarted';
    isa-ok $started.cro-file, Cro::Tools::CroFile, 'Have the Cro file object again';

    $got-body = test-request("http://localhost:$port/");
    ok $got-body.defined, 'Could call the restarted service';
    is $got-body, 'Service 1 UPDATED', 'Got response indicating new service running';

    $log = $other-messages.receive;
    isa-ok $log, Cro::Tools::Runner::Output, 'Got an output message from restarted service';
    nok $log.on-stderr, 'Was not on STDERR';
    ok $log.line ~~ /200/, 'Got log line mentioning status code';

    $run-tap.close;
    dies-ok {
            my $request = Cro::HTTP::Client.get("http://localhost:$port/");
            await Promise.anyof($request, Promise.in(10));
            die "Timed out" unless $request;
            await $request;
        },
        'Service is shut down when tap closed';
}

done-testing;
