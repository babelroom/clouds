
/* mini webserver for static files */

var he = require('./http_errors')
    ;

var Mini = function(config) {
    var mini = config.mini || {};
    this.root = mini.root || '/home/br/gits/clouds/gen/cdn_root';
    this.index = this.root + (mini.index || '/v1/c/index.html');
}

Mini.prototype = {
    addUseHandlers: function(express, app, options) {
        app.use('/cdn/', express.logger('short'));
        },

    addHandlers: function(express, app, options) {
        var self = this;
        function sendfile(path, req, res) {
            res.sendfile(path);
            }
        app.get(/^\/(favicon\.ico|robots\.txt)$/, function (req, res) { sendfile(self.root + '/v1/c/' + req.params[0], req, res); });
        app.get(/^\/cdn(\/.*)$/, function (req, res) { sendfile(self.root + req.params[0], req, res); });
        app.get('*', function (req, res) { sendfile(self.index, req, res); });
    }
}

module.exports = Mini;

