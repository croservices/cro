use Cro::Tools::CroFile;
use Cro::Tools::Template;
use META6;

class Cro::Tools::Template::ZeroMQWorkerService does Cro::Tools::Template {
    method id(--> Str) { 'zeromq-worker' }

    method name(--> Str) { 'ZeroMQ Worker Service' }

    method options(--> List) { () }

    method get-option-errors($options --> List) { () }

    method generate(IO::Path $where, Str $id, Str $name, %options) {
        write-entrypoint($where.add('service.p6'), $id, %options);
        write-cro-file($where.add('.cro.yml'), $id, $name, %options);
        write-meta($where.add('META6.json'), $name);
    }

    sub write-entrypoint($file, $id, %options) {
        my $env-name = env-name($id);
        my $entrypoint = q:to/CODE/;
        use Cro;
        use Cro::ZeroMQ::Service;
        use Cro::ZeroMQ::Message;

        class Worker does Cro::Transform {
            method consumes() { Cro::ZeroMQ::Message }
            method produces() { Cro::ZeroMQ::Message }
            method transformer(Supply $messages --> Supply) {
                supply {
                    whenever $messages {
                        say $_.perl;
                        emit Cro::ZeroMQ::Message.new('The work is done!');
                    }
                }
            }
        }

        my Cro::Service $service = Cro::ZeroMQ::Service.pull-push(
            pull-connect => "tcp://%*ENV<MY_TEST_ZMQ_SERVICE_HOST>:%*ENV<MY_TEST_ZMQ_SERVICE_PORT>",
            push-connect => "tcp://%*ENV<MY_TEST_ZMQ_SERVICE_HOST>:%*ENV<MY_TEST_ZMQ_SERVICE_PORT>",
            Worker);

        say "Listening at tcp://%*ENV<MY_TEST_ZMQ_SERVICE_HOST>:%*ENV<MY_TEST_ZMQ_SERVICE_PORT>";
        react {
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
            provides => {
                'Routes.pm6' => 'lib/Routes.pm6'
            },
            license => 'Write me!'
        );
        spurt($file, $m.to-json);
    }

    sub env-name($id) {
        $id.uc.subst(/<-[A..Za..z_]>/, '_', :g)
    }
}
