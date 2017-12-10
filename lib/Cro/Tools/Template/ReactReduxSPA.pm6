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
        self.write-frontend-reducer(%dir<frontend>.add('reducer.js'), $id);
        self.write-npm-package-config($where.add('package.json'), $id);
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

    method write-frontend-reducer($file, $id) {
        $file.spurt(self.frontend-reducer-contents($id));
    }

    method frontend-reducer-contents($id) {
        my $state   = $id ~ 'Text';
        my $reducer = $id ~ 'Reducer';
        my $action  = 'CHANGE_' ~ $id.uc ~ '_TEXT';
        q:s:to/CODE/;
            import * as ActionTypes from './actions';

            const initialState = {
                $state: '',
            };

            export function \qq[$reducer](state = initialState, action) {
                switch (action.type) {
                    case ActionTypes.$action:
                        return { ...state, $state: action.text };
                    default:
                        return state;
                }
            }
            CODE
    }

    method write-npm-package-config($file, $id) {
        $file.spurt(self.npm-package-config-contents($id));
    }

    method npm-package-config-contents($id) {
        q:s:to/CODE/;
            {
              "name": "$id",
              "version": "1.0.0",
              "description": "Write me!",
              "main": "index.js",
              "scripts": {
                "build": "webpack",
                "test": "echo \"Error: no test specified\" && exit 1"
              },
              "author": "",
              "license": "UNLICENSED",
              "private": true,
              "devDependencies": {
                "babel-core": "^6.26.0",
                "babel-loader": "^7.1.2",
                "babel-plugin-transform-object-rest-spread": "^6.26.0",
                "babel-preset-env": "^1.6.0",
                "babel-preset-es2015": "^6.24.1",
                "babel-preset-react": "^6.24.1",
                "webpack": "^3.6.0"
              },
              "dependencies": {
                "jquery": "^3.2.1",
                "react": "^16.0.0",
                "react-dom": "^16.0.0",
                "react-redux": "^5.0.6",
                "redux": "^3.7.2",
                "redux-thunk": "^2.2.0",
                "redux-websocket-action": "^1.0.5"
              }
            }
            CODE
    }

    method write-webpack-config($file) {
        $file.spurt(self.webpack-config-contents);
    }

    method webpack-config-contents() {
        q:to/CODE/;
            const path = require('path');

            module.exports = {
                entry: './frontend/index.js',
                output: {
                    filename: 'bundle.js',
                    path: path.resolve(__dirname, 'static/js')
                },
                module: {
                    loaders: [
                        {
                            test: /\.js/,
                            include: path.resolve(__dirname, 'frontend'),
                            loader: 'babel-loader'
                        }
                    ]
                }
            };
            CODE
    }

    method write-babelrc($file) {
        $file.spurt(self.babelrc-contents);
    }

    method babelrc-contents() {
        q:to/JSON/;
            {
                "presets" : ["es2015","react"],
                "plugins" : ["transform-object-rest-spread"]
            }
            JSON
    }
}
