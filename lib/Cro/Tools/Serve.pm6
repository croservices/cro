use Cro::HTTP::Router;
use Cro::HTTP::Server;

sub serve(Str $host, Int $port, Str $directory) is export {
    my $application = route {
        get -> *@path {
            static $directory, @path;
        }
    }
    given Cro::HTTP::Server.new(:$host, :$port, :$application) {
        .start;
        .return;
    }
}
