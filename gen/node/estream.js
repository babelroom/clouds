
/* work to write nodejs version of estream */

var net = require('net');

var EStream = function() {
}

EStream.prototype = {
    addHandlers: function(express, app, options) {
        var tcpip = options.tcpip;
        if (tcpip) {
            var sr = net.createServer(function(socket) {
                socket.write("net socket!\n");
                socket.pipe(socket);
                });
            sr.listen(tcpip.bindport, tcpip.bindaddr);
            }

        /* Make this resemble the estream binary response
        */
        app.disable('x-powered-by');
        app.disable('etag');    /* this doesn't work BTW -- these bunnies like thier cruft */
        app.use(function( req, res, next) {
            /*res.set({
                'ETag': undefined,
                }); */
            //res.removeHeader('X-Powered-By');
            res.removeHeader('ETag');
            next();
            });

        app.get('/rest/:file', function (req, res) {
            //res.sendfile(req.params.file, {root: options.dir, maxAge: undefined});
            //res.set('ETag',false);
            res.removeHeader('accept-ranges');
            res.sendfile(req.params.file, {root: options.dir, 'accept-ranges': undefined});
            });
        },
}

module.exports = EStream;

