use Cro::Tools::CroFile;
use Cro::Tools::Template;

class Cro::Tools::Template::ZeroMQWorkerService does Cro::Tools::Template {
    method id(--> Str) { 'zeromq-worksink' }

    method name(--> Str) { 'ZeroMQ Worker Service' }

    method options(--> List) { () }

    method get-option-errors($options --> List) { () }

    method generate(IO::Path $where, Str $id, Str $name, %options) {
        write-entrypoint($where.add('service.p6'), $id, %options);
        write-cro-file($where.add('.cro.yml'), $id, $name, %options);
    }

    sub write-entrypoint($file, $id, %options) {
        my $env-name = env-name($id);
        my $entrypoint = q:to/CODE/;
        use Cro::ZeroMQ::Collector;

        my $worker = Cro::ZeroMQ::Collector.pull(
            connect => "tcp://%*ENV<MY_TEST_ZMQ_SERVICE_HOST>:%*ENV<MY_TEST_ZMQ_SERVICE_PORT>");

        my $work = $worker.Supply.share;

        say "Listenint at tcp://%*ENV<MY_TEST_ZMQ_SERVICE_HOST>:%*ENV<MY_TEST_ZMQ_SERVICE_PORT>";
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

    sub write-cro-file($file, $id, $name, %options) {
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
            ]
        );
        $file.spurt($cro-file.to-yaml());
    }

    sub env-name($id) {
        $id.uc.subst(/<-[A..Za..z_]>/, '_', :g)
    }
}
