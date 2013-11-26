
var     http = require('http')
    ,   https = require('https')
    ,   DBManager = require('./db_manager')
    ,   SessionManager = require('./session_manager')
    ,   UDPSender = require('./udpsender')
    ,   AutoAPI = require('./auto_api')
    ,   fs = require('fs')
    ,   Live = require('./live')
    ,   API = require('./api')
    ,   Mini = require('./mini')
    ,   FileUploader = require('./file_uploader')

/*
** Read configuration 
*/
var config = {};
var config_file = './app_example_cfg.js';
for(var i=0; i<process.argv.length; i++)
    if (process.argv[i]=='-c')
        config_file = process.argv[i+1];    // will throw an exception if no arg
console.log('reading configuration from ['+config_file+']');
var config = require(config_file);

/* --- */
var protocol_factory = {
    http: function(options,app) { return http.createServer(app); },
    https: function(options,app) { return https.createServer({
        key: fs.readFileSync(options.key),
        cert: fs.readFileSync(options.cert)
        }, app)}
}
for(var i=0; i<config.groups.length; i++) {
    var g = config.groups[i];
    var servers = {};
    var db = new DBManager(g);
    var sessionManager = new SessionManager(g, db);
    var us = new UDPSender(config);
    var io = new Live(g);
    var api = new API(g, db, sessionManager, us);
    var fu = new FileUploader(g, db, sessionManager, us);
    var mini = new Mini(g);
    var express = require('express');
    var app = express();
    app.disable('x-powered-by');
    var groups = config.servers;
    for(var s in g.servers) {
        var se = g.servers[s];
        var sr = protocol_factory[se.protocol](se.options,app)
        sr.listen(se.bindport, se.bindaddr);
        io.addServer(sr, se);
        }
    for(var j=0; j<g.apps.length; j++)
        switch(g.apps[j]) {
            case 'live':
                io.addUseHandlers(express, app, g);
                break;
            case 'api':
                api.addUseHandlers(express, app, g);
                break;
            case 'mini':
                mini.addUseHandlers(express, app, g);
                break;
            case 'file_uploader':
                fu.addUseHandlers(express, app, g);
                break;
            }
    for(var j=0; j<g.apps.length; j++)
        switch(g.apps[j]) {
            case 'live':
                io.addHandlers(express, app, g);
                break;
            case 'api':
                api.addHandlers(express, app, g);
                break;
            case 'mini':
                mini.addHandlers(express, app, g);
                break;
            case 'file_uploader':
                fu.addHandlers(express, app, g);
                break;
            }
}

