use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Text::Markdown;

my $app = route {
    get -> {
        static $*CWD.IO.child('docs/reference/index.html');
    }
    get -> 'reference', $fn {
        my $path = $*CWD.IO.child('docs/reference').child($fn ~ '.md');
        if $path.IO.e {
            cache-control :public, :600max-age;
            content 'text/html', parse-markdown(slurp($path)).to_html;
        } else {
            not-found;
        }
    }
}

my $http-server = Cro::HTTP::Server.new(
    port => 28282,
    application => $app
);

say "Started carrying at 28282...";
$http-server.start;

await Promise.in(60 * 60);
