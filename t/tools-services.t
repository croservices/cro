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

with-test-dir -> $dir {
    my $services = Cro::Tools::Services.new(base-path => $dir.IO);
    my $found = $services.services.Channel;

    my $first-found = $found.receive;
    ok $first-found ~~ Cro::Tools::Services::Service,
        'Discovered one service existing at startup';
    my $second-found = $found.receive;
    ok $second-found ~~ Cro::Tools::Services::Service,
        'Discovered another service existing at startup';

    ($first-found, $second-found) = ($second-found, $first-found)
        if $first-found.path gt $second-found.path;

    is $first-found.path.Str, "$dir/nested/service2",
        'First service has correct path';
    is $first-found.cro-file.id, 'service2',
        'First service has correct .cro.yml';

    is $second-found.path.Str, "$dir/service1",
        'Second service has correct path';
    is $second-found.cro-file.id, 'service1',
        'Second service has correct .cro.yml';

    nok $found.poll, 'No third service discovered at start';
    mkdir "$dir/service3";
    spurt "$dir/service3/.cro.yml", q:to/YAML/;
        cro: 1
        id: service-3
        entrypoint: foo.p6
        YAML
    my $third-found = $found.receive;
    ok $third-found ~~ Cro::Tools::Services::Service,
        'Third service created after startup is found';
    is $third-found.path.Str, "$dir/service3",
        'Third service has correct path';
    is $third-found.cro-file.id, 'service-3',
        'Third service has correct .cro.yml';

    {
        my $s1-meta-change = $first-found.metadata-changed.Channel;
        my $s1-change = $first-found.source-changed.Channel;

        my $s2-meta-change = $second-found.metadata-changed.Channel;
        my $s2-change = $second-found.source-changed.Channel;

        nok $s1-meta-change.poll, 'No initial metadata change reported';
        spurt "$dir/nested/service2/.cro.yml",
            slurp("$dir/nested/service2/.cro.yml").subst('service.p6', 'start.p6');
        ok $s1-meta-change.receive, 'Metadata change received';
        is $first-found.cro-file.entrypoint, 'start.p6',
            'Cro file is reloaded';

        nok $s1-change.poll, 'No initial source change reported';
        mkdir "$dir/nested/service2/lib";
        spurt "$dir/nested/service2/lib/Foo.pm6", "say 42";
        is $s1-change.receive, "$dir/nested/service2/lib/Foo.pm6",
            'Got notified of changed service source file';

        nok $s2-meta-change.poll,
            'Metadata changes not mis-delivered to second service';
        nok $s2-change.poll,
            'Source changes not mis-delivered to second service';

        nok $second-found.cro-file-error.defined, 'No exception is set when no error';
        spurt "$dir/service1/.cro.yml", ": invalid stuff!";
        ok $s2-meta-change.receive,
            'Got notification of change to second service .cro.yml';
        nok $second-found.cro-file.defined, 'Parse error gives undefined .cro-file';
        ok $second-found.cro-file-error.defined, 'Exception is set on error';
    }

    {
        my $s3-meta-done = Promise.new;
        my $s3-done = Promise.new;
        $third-found.metadata-changed.tap: done => { $s3-meta-done.keep };
        $third-found.source-changed.tap: done => { $s3-done.keep };
        my $deleted = $third-found.deleted;

        rm_rf "$dir/service3";
        await Promise.anyof($deleted, Promise.in(5));
        ok $deleted, 'Deleted Promise kept when service deleted';

        await Promise.anyof(Promise.allof($s3-meta-done, $s3-done), Promise.in(5));
        ok $s3-meta-done, 'Metadata changed Supply done when service deleted';
        ok $s3-done, 'Source changed Supply done when service deleted';

        ok $third-found.deleted,
            'Getting deleted Promise after deletion has it completed';
    }
}

done-testing;
