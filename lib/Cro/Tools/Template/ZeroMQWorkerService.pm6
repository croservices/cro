use Cro::Tools::CroFile;
use Cro::Tools::Template;
use Cro::Tools::Template::Common;
use META6;

class Cro::Tools::Template::ZeroMQWorkerService does Cro::Tools::Template does Cro::Tools::Template::Common {
    method id(--> Str) { 'zeromq-worker' }

    method name(--> Str) { 'ZeroMQ Worker Service' }

    method options(--> List) { () }

    method get-option-errors($options --> List) { () }

    method generate(IO::Path $where, Str $id, Str $name, %options, $generated-links, @links) {
        die "Horrible death";
        self.generate-common($where, $id, $name, %options, $generated-links, @links);
    }

    method entrypoint-contents($id, %options, $links) {
        my $env-name = self.env-name($id);
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
        $service.start;

        say "Listening at tcp://%*ENV<MY_TEST_ZMQ_SERVICE_HOST>:%*ENV<MY_TEST_ZMQ_SERVICE_PORT>";
        react {
            whenever signal(SIGINT) {
                say "Shutting down...";
                $service.close;
                done;
            }
        }
        CODE
    }

    method cro-file-endpoints($id-uc, %options) {
        Cro::Tools::CroFile::Endpoint.new(
            id => 'zmq',
            name => 'ZeroMQ',
            protocol => 'tcp',
            host-env => $id-uc ~ '_HOST',
            port-env => $id-uc ~ '_PORT'
        ),
    }

    method meta6-depends(%options) { <Cro::ZMQ> }

    method meta6-provides(%options) { () }

    method meta6-resources(%options) { () }
}
