
/* work to write nodejs version of estream */

var http = require('http');
var fs = require('fs');

/*
** Read configuration 
*/
var config = {};
var config_file = './es_example_cfg.js';
for(var i=0; i<process.argv.length; i++)
    if (process.argv[i]=='-c')
        config_file = process.argv[i+1];    // will throw an exception if no arg
console.log('reading configuration from ['+config_file+']');
var config = require(config_file);

/*
** EC/ECM
*/
function EventQueue() {
    this.lsn = 0;
    this.queue = [];
    this.callbacks = [];
}
EventQueue.prototype.put = function(data) {
    this.queue.push(data);
}
EventQueue.prototype.get = function(from_lsn) {
    /* OK, got to think this thru a bit ... */
}

var g_ecm = {
    _event_queues: {},
    find: function(queue_name, can_create) {
        var eq = this._event_queues[queue_name];
        if (eq) return eq;
        if (can_create)
            eq = this._event_queues[queue_name] = new EventQueue();
        return eq;
        }
}

/* --- */
function send_result(res, status, msg) {
    res.writeHead(status, { 'Content-Length': msg.length});
    res.end(msg);
}

/* --- */
function sendFile(path, res, is_send) {
    fs.stat(path, function(err, stats){
        if (err)
            return send_result(res, 404, 'Not Found');
        else
            fs.readFile(path, function(err, data){
                if (err)
                    return send_result(res, 500, 'Internal error');
                res.setHeader('Last-Modified', stats.mtime.toUTCString());
                res.writeHead(200, { 'Content-Length': data.length});
                res.end(is_send ? data : '');
                });
            });
}

/* --- */
function postOrPutFile(req, path, res, is_post) {
    function checkForFile(path, res, is_post, data) {
        function putfile( path, res, data) {
            fs.writeFile(path, data, function(err) {
                if (err)
                    return send_result(res, 500, 'Internal error');
                send_result(res, is_post?200/*for back compat.*/:200, '');
                });
            }
        if (is_post) return putfile(path, res, data);
        else fs.stat(path, function(err, stats) {
            if (err || !stats || !stats.isFile())
                return send_result(res, 404, 'Not Found');
            return putfile(path, res, data);
            });
        }
    var data = '';
    req
        .on('data',function(chunk){
            data += chunk;
            })
        .on('end',function(){
            return checkForFile(path, res, is_post, data);
            })
        ;
}

/* --- */
function deleteFile(path, res) {
    fs.unlink(path, function(err){
        if (err) return send_result(res, 500, 'Internal server error');
        else send_result(res, 200, 'Deleted');
        });
}

/* --- */
function restfile(req, path, res) {
    switch(req.method) {
        case 'GET' : return sendFile(path, res, true);
        case 'HEAD': return sendFile(path, res, false);
        case 'POST': return postOrPutFile(req, path, res, true);
        case 'PUT' : return postOrPutFile(req, path, res, false);
        default:
            return error(res, 405, 'Method not supported');
        }
}

/* --- */
function postOrPutEBus(req, queue, res, is_post) {
    function fn(queue, res, is_post, data) {
        eq = g_ecm.find(queue, is_post);
        eq.put(data);
        send_result(res, 200, 'OK');
        }
    var data = '';
    req
        .on('data',function(chunk){
            data += chunk;
            })
        .on('end',function(){
            return fn(queue, res, is_post, data);
            })
        ;
}

/* --- */
function ebus(req, queue, res) {
    switch(req.method) {
/*        case 'GET' : return sendFile(path, res, true);
        case 'HEAD': return sendFile(path, res, false); */
        case 'POST': return postOrPutEBus(req, queue, res, true);
        case 'PUT' : return postOrPutEBus(req, queue, res, false);
        default:
            return error(res, 405, 'Method not supported');
        }
}

/* --- */
if (config.http) {
    http.createServer(function(req, res){
        var arr;
        if (false) ;
        else if (arr=/^\/fs(\/.*)$/.exec(req.url))
            ebus(req, arr[1], res);
        else if (arr=/^\/conference(\/.*)$/.exec(req.url))
            ebus(req, arr[1], res);
        else if (arr=/^\/rest(\/.*)$/.exec(req.url))
            restfile(req, config.dir_rest + arr[1],res);
        else if (arr=/^\/cs_media(\/.*)$/.exec(req.url))
            restfile(req, config.dir_cs_media + arr[1],res);
        else 
            { res.writeHead(500); res.end('Server Error'); }
        }).listen(config.http.bindport, config.http.bindaddr);
    }

/* --- */
if (config.tcpip) {
    }

