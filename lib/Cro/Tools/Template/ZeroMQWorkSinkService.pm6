use Cro::Tools::CroFile;
use Cro::Tools::Template;
use META6;

class Cro::Tools::Template::ZeroMQWorkSinkService does Cro::Tools::Template {
    method id(--> Str) { 'zeromq-worksink' }

    method name(--> Str) { 'ZeroMQ Work Sink Service' }

    method options(--> List) { () }

    method get-option-errors($options --> List) { () }

    method generate(IO::Path $where, Str $id, Str $name,
                    %options, $generated-links, @links) {
        write-entrypoint($where.add('service.p6'), $id, %options);
        write-cro-file($where.add('.cro.yml'), $id, $name, %options, @links);
        write-meta($where.add('META6.json'), $name);
    }

    sub write-entrypoint($file, $id, %options) {
        my $env-name = env-name($id);
        my $entrypoint = q:to/CODE/;
        use Cro::ZeroMQ::Collector;

        my $worker = Cro::ZeroMQ::Collector.pull(
            connect => "tcp://%*ENV<MY_TEST_ZMQ_SERVICE_HOST>:%*ENV<MY_TEST_ZMQ_SERVICE_PORT>");

        my $work = $worker.Supply.share;

        say "Listening at tcp://%*ENV<MY_TEST_ZMQ_SERVICE_HOST>:%*ENV<MY_TEST_ZMQ_SERVICE_PORT>";
        react {
            whenever $work {
                say $work.perl;
            }

            whenever signal(SIGINT) {
                say "Shutting down...";
                $work.close;
                done;
            }
        }
        CODE

        $file.spurt($entrypoint);
    }

    sub write-cro-file($file, $id, $name, %options, @links) {
        my $id-uc = env-name($id);
        my $cro-file = Cro::Tools::CroFile.new(
            :$id, :$name, :entrypoint<service.p6>, :entrypoints[
                Cro::Tools::CroFile::Endpoint.new(
                    id => 'zmq',
                    name => 'ZeroMQ',
                    protocol => 'tcp',
                    host-env => $id-uc ~ '_HOST',
                    port-env => $id-uc ~ '_PORT'
                )
            ], :@links
        );
        $file.spurt($cro-file.to-yaml());
    }

    sub write-meta($file, $name) {
        my $m = META6.new(
            name => $name,
            description => 'Write me!',
            version => Version.new('0.0.1'),
            perl-version => Version.new('6.*'),
            depends => <Cro::ZMQ>,
            tags => (''),
            authors => (''),
            auth => 'Write me!',
            source-url => 'Write me!',
            support => META6::Support.new(
                source => 'Write me!'
            ),
            provides => {},
            license => 'Write me!'
        );
        spurt($file, $m.to-json);
    }

    sub env-name($id) {
        $id.uc.subst(/<-[A..Za..z_]>/, '_', :g)
    }
}
