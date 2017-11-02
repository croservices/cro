const path = require('path');

module.exports = {
    entry: './src/index.js',
    output: {
        filename: 'app.js',
        path: path.resolve(__dirname, '../resources/web/js')
    },
    module : {
        loaders : [
            {
                test: /\.js/,
                include: path.resolve(__dirname, 'src'),
                loader: 'babel-loader'
            }
        ]
    }
};
