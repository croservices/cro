use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::HTTP::Log::File;

my $routes = route {
    get -> {
        content 'text/plain', 'Service 1 OK';
    }
}

my Cro::Service $http = Cro::HTTP::Server.new(
    http => '1.1',
    host => %*ENV<SERVICE1_HTTP_HOST> ||
        die("Missing SERVICE1_HTTP_HOST in environment"),
    port => %*ENV<SERVICE1_HTTP_PORT> ||
        die("Missing SERVICE1_HTTP_PORT in environment"),
    application => $routes,
    after => [
        Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
    ]
);
$http.start;
react {
    whenever signal(SIGINT) {
        $http.stop;
        done;
    }
}
