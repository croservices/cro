use Cro::Tools::CroFile;
use Cro::Tools::Template;
use Cro::Tools::Template::Common;

class Cro::Tools::Template::ZeroMQWorkerService does Cro::Tools::Template does Cro::Tools::Template::Common {
    method id(--> Str) { 'zeromq-worker' }

    method name(--> Str) { 'ZeroMQ Worker Service' }

    method options(--> List) { () }

    method get-option-errors($options --> List) { () }

    method generate(IO::Path $where, Str $id, Str $name, %options, $generated-links, @links) {
        self.generate-common($where, $id, $name, %options, $generated-links, @links);
    }

    method entrypoint-contents($id, %options, $links) {
        my $env-name = self.env-name($id);
        my $pull-service = 'MY_TEST_ZMQ_SERVICE';
        my $push-service = 'MY_TEST_ZMQ_SERVICE';
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

        CODE

        $entrypoint ~= q:c:to/CODE/;
        my $pull-connect = "tcp://%*ENV<{$pull-service}_HOST>:%*ENV<{$pull-service}_PORT>";
        my $push-connect = "tcp://%*ENV<{$push-service}_HOST>:%*ENV<{$push-service}_PORT>";
        my Cro::Service $service = Cro::ZeroMQ::Service.pull-push(:$pull-connect, :$push-connect, Worker);
        $service.start;

        say "Pulling at $pull-connect";
        say "Pushing at $push-connect";
        CODE

        $entrypoint ~= q:to/CODE/;
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
}
