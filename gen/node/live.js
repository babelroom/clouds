
/* --- */

var http = require('http')
    ;

var put_templates = {
    /* admin only */
    clear: {q: 'conference', fmt: function(d){return "K"+d.args;}},
    command: {q: 'conference', fmt: function(d){return "Kcommand"+d.args;}},
    conferenceAction: {q: 'fs', fmt: function(d){return 'Fbgapi conference '+d.cid+' '+d.args;}},
    move: {q: 'fs', fmt: function(d){return 'Fbgapi conference '+d.cid+' group '+d.args[0]+' '+d.args[1];}},

    /* everybody */
    chat: {q: 'conference', fmt: function(d){return "C"+d.args;}, nonpriv: true},
    video: {q: 'conference', fmt: function(d){return "Kvideo"+d.args;}, nonpriv: true},
    slide: {q: 'conference', fmt: function(d){return "Kslide"+d.args;}, nonpriv: true},
    conferenceIdsAction: {q: 'fs', fmt: function(d){return 'M'+d.args[0]+' bgapi conference '+d.cid+' '+d.args[1];}, nonpriv: true},   /*temporarily allowed by non-admins (mute)*/
    gue: {q: 'conference', fmt: function(d){return "Kgue-"+d.args.idx+d.args.attr+d.args.value;}, nonpriv: true},

    /* TODO tmp */
    dialCmd: {q: 'fs_', fmt: function(d){return d.args;}, nonpriv: true},  /* scary */
};

var Live = function(config) {
    this.socket_io = undefined;
    this.servers = {};
    this.config = config;
}

/* --- */
function get(socket, name)
{
    /* socket.set('estreamRequest',value, functio CB??) = req; tmp TODO -- use this instead? -- whats the deal with the cb? */
    return socket._br_data ? socket._br_data[name] : undefined;
}
function set(socket, name, value)
{
    if (typeof(socket._br_data)==='undefined')
        socket._br_data = {};
    socket._br_data[name] = value;
}

/* --- */
function estream_get(es, socket, url_suffix, fn)
{
    var req = http.request({hostname: es.hostname, port: es.port, path: '/conference/'+url_suffix, method: 'GET', agent: false}, function(res) {
        if (res.statusCode==200) {
            fn(true);
            res.on('data', function (chunk) {
                socket.send(chunk);
                });
            res.on('end', function (chunk) {     // TMP todo I think chunk here is wrong
                // disconnection from estream
                socket.disconnect();
                });
            }
        else {
            console.log('status code '+res.statusCode);
            fn(false);
            }
        });
    req.on('error', function(e) {
        // such as connection refused
        console.log('problem with request: ' + e.message);
        fn(false);
        });
    set(socket, 'estreamRequest', req);
    req.end();
}

/* --- */
function estream_put(es, socket, data)
{
    var options = {
        hostname: es.hostname,
        port: es.port,
        path: data.queue,
        method: 'PUT',
        headers: {
            //'Content-Length': data.data.length,    -- no, will truncate non-ascii chars in utf8 string
            'Content-Length': Buffer.byteLength(data.data), // yes
            'Connection': 'close'
            }
        }
    var req = http.request(options, function(res) {
        if (res.statusCode!=200) {  // estream return 200 even for POST (i.e. create) 
            console.log('bad status code for PUT: ' + res.statusCode + '[' + JSON.stringify(data) + '], [' + JSON.stringify(options) + ']');
            }
        });
    req.on('error', function(e) {
        // such as connection refused
        console.log('problem with request: ' + e.message);
        });
    req.write(data.data);
    req.end();
}

/* --- */
function br_api_call(api_host, socket, data, fn)
{
    if (false /* not right ---- data.data && typeof(data.data)!=='string'*/) {
        /* TMP todo .. more sanity check data from client .. */
        console.log('API proxy request failed sanity check', data);
        return fn(null);
        }
    var requestHeaders = {
        //'Cookie': data.cookie,
        'Cookie': socket.handshake.headers.cookie,
        }
    var data2Send = '';
    if (data.data) {
        try { data2Send = JSON.stringify(data.data); }
        catch(e) {
            console.log('Error marshalling API request data', data);
            return fn('Error marshalling API request data',null);
            }
        requestHeaders['Content-Type'] = 'application/json; charset=utf-8';
        requestHeaders['Content-Length'] = Buffer.byteLength(data2Send);    /* !data2Send.length, overkill? */
        }
    var requestOptions = {
        method: data.verb,
        host: api_host.hostname,
        port: api_host.port,
        path: data.path,
        headers: requestHeaders,
        agent: false,   /* possibly take a performance hit, but cleaner ... */
        }
    var request = null;
    try {request = http.request(requestOptions); }
    catch(e) {
        // this is called when the parameters are bad
        console.log('Exception forwarding API request: ',e,data);
        fn('Exception forwarding API request', null);
        return;
        }
    request.on('error', function(e){
        console.log('Error forwarding API request: ',e);
        fn('Error forwarding API request', null);
        });
    request.on('response', function(response){
        var result = '';
        response.on('data',function(chunk){
            result += chunk;
            });
        response.on('end',function(chunk){
            fn(null, result);
            });
        });
    if (data2Send)
        request.write(data2Send);
    request.end();
}

/* --- */
Live.prototype = {
    addServer: function(sr,se) {
        var key = se.bindaddr+'-'+se.bindport;
        this.servers[key] = sr;
        },
    addCallbacks: function(io, key) {
/* for ref:
https://github.com/LearnBoost/socket.io/wiki/Authorizing
io.configure(function (){
  io.set('authorization', function (handshakeData, callback) {
*/
        io.set('resource', '/sio');
        /* need this for IE at least */
        io.set('transports', [ 'websocket' , 'flashsocket' , 'htmlfile' , 'xhr-polling' , 'jsonp-polling' ]);

        //io.enable('browser client minification');
        var _this = this, es = this.config.estream, api_host = this.config.api;
        io.sockets.on('connection', function (socket) {
        console.log('UA',socket.handshake.headers['user-agent']);
/*
            socket.on('message', function(data){    /* attach *./
                var cid = parseInt(data), admin = get(socket, 'access_'+cid);
                if (typeof(admin)!=='undefined')
                    estream_get(es, socket, data, function(){});
                });
*/
            socket.on('br_attach', function (data,fn) {
                var cid = parseInt(data||0), admin = get(socket, 'access_'+cid);
                if (typeof(admin)!=='undefined')
                    estream_get(es, socket, data, fn);
                else
                    fn(false);
                });
            socket.on('br_add_conference_credential', function (data,fn) {
                try { data = JSON.parse(data); }
                catch(e) {
                    console.log('JSON.parse exception: ['+e+'], ['+data+']');
                    fn({'foo':1});
                    return ;
                    }
                /* TODO -- marshall the login_tokin to the api call: data.token */
                var data = {
                    verb: 'GET',
                    path: '/api/v1/invitation'+data.path,
                    };
                br_api_call(api_host, socket, data, function(e,d){
                    if (e || !d) return fn(null);
                    try { d = JSON.parse(d); }
                    catch(e) {
                        console.log('JSON.parse exception',d);
                        fn(null);
                        }
                    if (!d.data) return fn(null);
                    set(socket, 'access_'+d.data.conference_estream_id, d.data.is_host);
                    fn(d);
                    });
                });
/*
            socket.on('br_old_put', function (data) {
                try { data = JSON.parse(data); }
                catch(e) {
                    console.log('JSON.parse exception: ['+e+'], ['+data+']');
                    return ;
                    }
                var admin = undefined;
                if (data && data.queue && /(\d+)$/.exec(data.queue))
                    admin = get(socket, 'access_'+RegExp.$1);
                if (typeof(admin)!=='undefined') {
                    try { estream_put(es, socket, data); }
                    catch(e) {
                        console.log('estream exception: ['+e+'], ['+data+']');
                        }
                    }
                else
                    console.log('(old) put request access denied',data);
                });
*/
            socket.on('br_put', function (data) {
                try { data = JSON.parse(data); }
                catch(e) {
                    console.log('JSON.parse exception: ['+e+'], ['+data+']');
                    return ;
                    }
                var map = null;
                if (!data || !data.cid || typeof(data.args)==="undefined" || !data.template || !(map=put_templates[data.template]))
                    return console.log('br_put: invalid input',data);
                var admin = get(socket, 'access_'+data.cid);
                if (typeof(admin)!=='undefined' && (map.nonpriv || admin===true)) {
                    data.queue = ((map.q==='fs_') ? '/fs/_' : ('/'+map.q+'/'+data.cid));
                    data.data = map.fmt(data);
                    try { estream_put(es, socket, data); }
                    catch(e) {
                        console.log('estream exception: ['+e+'], ['+data+']');
                        }
                    }
                else
                    console.log('put request access denied',data);
                });
            socket.on('br_api', function (data, fn) {
                br_api_call(api_host, socket, data, function(e,d){
                    fn( ((!e)&&d)? d: null);
                    });
                });
            socket.on('disconnect', function (data) {
                var er=get(socket, 'estreamRequest');
                if (er)
                    er.abort();
                });
            });
        },
    listen: function(server) {
        if (!this.socket_io)
            this.socket_io = require('socket.io');
        for(var key in this.servers)
            if (this.servers.hasOwnProperty(key)) {
                console.log(key);   // why?
                var io = this.socket_io.listen(this.servers[key]);
                this.addCallbacks(io, key);
                }
        },

    addUseHandlers: function(_, _, _) {;},
    addHandlers: function(_, app, _) {
        this.listen();
/*        app.use(function(req, res, next){
            console.log('%s %s', req.method, req.url);
            next();
            }); */
        app.get('/', function (req, res) {
            res.sendfile(__dirname + '/index.html');
            });
        app.get('/ssl', function (req, res) {
            res.sendfile(__dirname + '/index_ssl.html');
            });
        }
}

module.exports = Live;

