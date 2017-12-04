use Cro::Tools::Template::HTTPService;

class Cro::Tools::Template::ReactReduxSPA is Cro::Tools::Template::HTTPService {
    method id(--> Str) { 'react-redux-spa' }

    method name(--> Str) { 'React/Redux Single Page Application' }

    method generate(IO::Path $where, Str $id, Str $name,
                    %options, $generated-links, @links) {
        my %dir = self.make-directories($where);
        self.write-static-index(%dir<static>.add('index.html'), $name);
        self.write-frontend-index(%dir<frontend>.add('index.js'));
        self.write-frontend-actions(%dir<frontend>.add('actions.js'));
        self.write-frontend-reducer(%dir<frontend>.add('reducer.js'));
        self.write-npm-package-config($where.add('package.json'));
        self.write-webpack-config($where.add('webpack.config.js'));
        self.write-babelrc($where.add('.babelrc'));
        nextsame;
    }

    method new-directories($where) {
        my $static = $where.add('static');
        |callsame,
        static    => $static,
        static-js => $static.add('js'),
        frontend  => $where.add('frontend')
    }

    method write-static-index($file, $name) {
        $file.spurt(self.static-index-contents($name));
    }

    method static-index-contents($name) {
        q:c:to/HTML/;
            <html>
              <head>
                <title>{$name}</title>
              </head>
              <body>
                <h1>{$name}</h1>
                <div id="app"></div>
                <script src="js/bundle.js"></script>
              </body>
            </html>
            HTML
    }

    method write-frontend-index($file) {
        $file.spurt(self.frontend-index-contents);
    }

    method frontend-index-contents() {
        'TODO'
    }

    method write-frontend-actions($file) {
        $file.spurt(self.frontend-actions-contents);
    }

    method frontend-actions-contents() {
        'TODO'
    }

    method write-frontend-reducer($file) {
        $file.spurt(self.frontend-reducer-contents);
    }

    method frontend-reducer-contents() {
        'TODO'
    }

    method write-npm-package-config($file) {
        $file.spurt(self.npm-package-config-contents);
    }

    method npm-package-config-contents() {
        'TODO'
    }

    method write-webpack-config($file) {
        $file.spurt(self.webpack-config-contents);
    }

    method webpack-config-contents() {
        'TODO'
    }

    method write-babelrc($file) {
        $file.spurt(self.babelrc-contents);
    }

    method babelrc-contents() {
        'TODO'
    }
}
