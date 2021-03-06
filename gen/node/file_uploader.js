'use strict';

var he = require('./http_errors');

var FileUploader = function(config, dbManager, sessionManager, us) {
    this.db = dbManager;
    this.sessionManager = sessionManager;
    this.us = us;
    this.options = {
            tmpdir: __dirname + '/home/br/tmp/files',
//            publicDir: '/home/br/tmp/files',
            uploadDir: '/home/br/tmp/files',
//            uploadUrl: '/files/',   // ??
            maxPostSize: 11000000000, // 11 GB
            minFileSize: 1,
            maxFileSize: 10000000000, // 10 GB
            //maxFileSize: 2000000, // 2MB

/* the next few options are not used */
            acceptFileTypes: /.+/i,
            // Files not matched by this regular expression force a download dialog,
            // to prevent executing any scripts in the context of the service domain:
            inlineFileTypes: /\.(gif|jpe?g|png)$/i,
            imageTypes: /\.(gif|jpe?g|png)$/i,
            imageVersions: {
                'thumbnail': {
                    width: 80,
                    height: 80
                }
            },
/* but this is ... */
            accessControl: {
                allowOrigin: '*',
                allowMethods: 'OPTIONS, HEAD, GET, POST, PUT, DELETE',
                allowHeaders: 'Content-Type, Content-Range, Content-Disposition'
            },
/*
            nodeStatic: {
                cache: 3600 // seconds to cache served files
            }
*/
        };
        var co = config.file_uploader || {};
        for(var o in co)
            if (co.hasOwnProperty(o))
                this.options[o] = co[o];
}

FileUploader.prototype = {
    addUseHandlers: function(express, app, options) {
        app.use('/upl/', express.logger('short'));
        },

    addHandlers: function(express, app, options) {
        var self = this;
        app.all(/^\/upl\/$/, function(req, res){
            try {
                    req._fu = self;
                    serve(req, res);
                } catch(e) {
                    console.log(e.stack)
                };
            });
    }
}

module.exports = FileUploader

/*
JR 11/2013: The following code is derived as noted below. Modified, errors/ugliness are mine
*/
/*
 * jQuery File Upload Plugin Node.js Example 2.1.0
 * https://github.com/blueimp/jQuery-File-Upload
 *
 * Copyright 2012, Sebastian Tschan
 * https://blueimp.net
 *
 * Licensed under the MIT license:
 * http://www.opensource.org/licenses/MIT
 */


/* --- */
    var path = require('path'),
        fs = require('fs'),
        // Since Node 0.8, .existsSync() moved from path to fs:
        _existsSync = fs.existsSync || path.existsSync,
        formidable = require('formidable'),
//        nodeStatic = require('node-static'),
//        imageMagick = require('imagemagick'), -- JR
/*
        utf8encode = function (str) {
            return unescape(encodeURIComponent(str));
        },
*/
//        fileServer = new nodeStatic.Server(options.publicDir, options.nodeStatic),

        nameCountRegexp = /(?:(?: \(([\d]+)\))?(\.[^.]+))?$/,
        nameCountFunc = function (s, index, ext) {
            return ' (' + ((parseInt(index, 10) || 0) + 1) + ')' + (ext || '');
        },
        FileInfo = function (file) {
            this.name = file.name;
            this.size = file.size;
            this.type = file.type;
            this.deleteType = 'DELETE';
        },
        UploadHandler = function (req, res, callback) {
            this.req = req;
            this.res = res;
            this.callback = callback;
        },

        serve = function (req, res) {
            var fu = req._fu;
            res.setHeader(
                'Access-Control-Allow-Origin',
                fu.options.accessControl.allowOrigin
            );
            res.setHeader(
                'Access-Control-Allow-Methods',
                fu.options.accessControl.allowMethods
            );
            res.setHeader(
                'Access-Control-Allow-Headers',
                fu.options.accessControl.allowHeaders
            );
            var handleResult = function (result, redirect) {
                    if (redirect) {
                        res.writeHead(302, {
                            'Location': redirect.replace(
                                /%s/,
                                encodeURIComponent(JSON.stringify(result))
                            )
                        });
                        res.end();
                    } else {
                        res.writeHead(200, {
                            'Content-Type': req.headers.accept
                                .indexOf('application/json') !== -1 ?
                                        'application/json' : 'text/plain'
                        });
                        res.end(JSON.stringify(result));
                    }
                },
                setNoCacheHeaders = function () {
                    res.setHeader('Pragma', 'no-cache');
                    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
                    res.setHeader('Content-Disposition', 'inline; filename="files.json"');
                },
                handler = new UploadHandler(req, res, handleResult);
            switch (req.method) {
            case 'OPTIONS':
                res.end();
                break;
            case 'HEAD':
            case 'GET':
                res.end();
/*
                if (req.url === '/') {
                    setNoCacheHeaders();
                    if (req.method === 'GET') {
                        handler.get(fu);
                    } else {
                        res.end();
                    }
                } else {
//                    fileServer.serve(req, res);
                }
*/
                break;
            case 'POST':
                setNoCacheHeaders();
                handler.post(fu);
                break;
            case 'DELETE':
                handler.destroy(fu);
                break;
            default:
                res.statusCode = 405;
                res.end();
            }
        };

/*
    fileServer.respond = function (pathname, status, _headers, files, stat, req, res, finish) {
        // Prevent browsers from MIME-sniffing the content-type:
        _headers['X-Content-Type-Options'] = 'nosniff';
        if (!XXXXXXXXXfu.options.inlineFileTypes.test(files[0])) {
            // Force a download dialog for unsafe file extensions:
            _headers['Content-Type'] = 'application/octet-stream';
            _headers['Content-Disposition'] = 'attachment; filename="' +
                utf8encode(path.basename(files[0])) + '"';
        }
        nodeStatic.Server.prototype.respond
            .call(this, pathname, status, _headers, files, stat, req, res, finish);
    };
*/
    FileInfo.prototype.validate = function (fu) {
        var options = fu.options;
        if (options.minFileSize && options.minFileSize > this.size) {
            this.error = 'File is too small';
        } else if (options.maxFileSize && options.maxFileSize < this.size) {
            this.error = 'File is too big';
        } else if (!options.acceptFileTypes.test(this.name)) {
            this.error = 'Filetype not allowed';
        }
        return !this.error;
    };
    FileInfo.prototype.safeName = function (fu) {
        // Prevent directory traversal and creating hidden system files:
        this.name = path.basename(this.name).replace(/^\.+/, '');
        // Prevent overwriting existing files:
        while (_existsSync(fu.options.uploadDir + '/' + this.name)) {
            this.name = this.name.replace(nameCountRegexp, nameCountFunc);
        }
    };
    FileInfo.prototype.initUrls = function (req) {
        var options = req._fu.options;
/* not used
        if (!this.error) {
            var that = this,
                baseUrl = (options.ssl ? 'https:' : 'http:') +
                    '//' + req.headers.host + options.uploadUrl;
            this.url = this.deleteUrl = baseUrl + encodeURIComponent(this.name);
            Object.keys(options.imageVersions).forEach(function (version) {
                if (_existsSync(
                        options.uploadDir + '/' + version + '/' + that.name
                    )) {
                    that[version + 'Url'] = baseUrl + version + '/' +
                        encodeURIComponent(that.name);
                }
            });
        }
*/
    };
    UploadHandler.prototype.get = function (fu) {
/* not used
        var handler = this,
            files = [];
        fs.readdir(fu.options.uploadDir, function (err, list) {
            list.forEach(function (name) {
                var stats = fs.statSync(fu.options.uploadDir + '/' + name),
                    fileInfo;
                if (stats.isFile() && name[0] !== '.') {
                    fileInfo = new FileInfo({
                        name: name,
                        size: stats.size
                    });
                    fileInfo.initUrls(handler.req);
                    files.push(fileInfo);
                }
            });
            handler.callback({files: files});
        });
*/
    };
    UploadHandler.prototype.post = function (fu) {
        var handler = this,
            form = new formidable.IncomingForm(),
            tmpFiles = [],
            files = [],
            map = {},
            md_map = {},
            counter = 1,
            redirect,
            finish = function () {
                try {
                    counter -= 1;
                    if (!counter) {
                        files.forEach(function (fileInfo) {
                            fileInfo.initUrls(handler.req);
                            });
                        handler.callback({files: files}, redirect);
                        }
                    }
                catch(e) { console.log(e.stack) };
            };
        form.uploadDir = fu.options.tmpdir;
        var user_id, conference_id, csrf_token;
        form.on('fileBegin', function (name, file) {
            try {
/* for reference:
console.log([name,file]);
[ 'media_file[upload]',
  { domain: null,
    _events: null,
    _maxListeners: 10,
    size: 0,
    path: '/home/br/tmp/upl/9c36a3690ec100e424501f6fce71e334',
    name: 'Example.png',
    type: 'image/png',
    hash: null,
    lastModifiedDate: null,
    _writeStream: null } ]
*/
                var check_csrf_token = fu.sessionManager.md5_token(conference_id, user_id, 0);
                /* note we can't check file size at this point as we have to wait for upload */
                if (check_csrf_token!==csrf_token) {
                    he.forbidden(handler.res);
                    console.log('csrf token mismatch');
                    handler.req.connection.destroy();   /* seems this doesn't actually do much ... */
                    return ;
                    }
                tmpFiles.push(file.path);
                var fileInfo = new FileInfo(file, handler.req, true);
                fileInfo.safeName(fu);
                map[path.basename(file.path)] = fileInfo;
                files.push(fileInfo);
                }
            catch(e) { console.log(e.stack); }
        }).on('field', function (name, value) {
            try {
//console.log(['Field',name,value]);
                switch(name) {
                    case 'redirect': redirect = value; break;
                    case 'media_file[csrf_token]': csrf_token = value; break;
                    case 'media_file[user_id]': user_id = value; break;
                    case 'media_file[conference_id]': conference_id = value; break;
                    }
                }
            catch(e) { console.log(e.stack); }
        }).on('file', function (name, file) {
            try {
                var fileInfo = map[path.basename(file.path)];
                if (!fileInfo)
                    return;
                fileInfo.size = file.size;
                if (!fileInfo.validate(fu)) {
                    fs.unlink(file.path);
                    return;
                }
/*
console.log([file.path, fu.options.uploadDir + '/' + fileInfo.name]);
                /* NB: if this has to copy across devices we'll have a real big problem (read: temporary system outage) *./
                fs.renameSync(file.path, fu.options.uploadDir + '/' + fileInfo.name);
*/
//                fs.symlinkSync(file.path, fu.options.uploadDir + '/' + fileInfo.name); -- may make things easier, but seems to have some problems ...
// aaaaaahhh original file removed, link remains, test doesn't see old file => uses same name, then create fails as symlink exists ...
/* JR
                if (fu.options.imageTypes.test(fileInfo.name)) {
                    Object.keys(fu.options.imageVersions).forEach(function (version) {
                        counter += 1;
                        var opts = fu.options.imageVersions[version];
                        imageMagick.resize({
                            width: opts.width,
                            height: opts.height,
                            srcPath: fu.options.uploadDir + '/' + fileInfo.name,
                            dstPath: fu.options.uploadDir + '/' + version + '/' +
                                fileInfo.name
                        }, finish);
                    });
                    }
*/
                /* NB: conference_id, user_id field here are temporary, pending reference counting implementation */
                var sql = "INSERT INTO media_files(conference_id,user_id,name,content_type,size,url,created_at,updated_at,driver) VALUES (?,?,?,?,?,?,NOW(),NOW(),'fs');";
                fu.db.query(sql, [conference_id,user_id,fileInfo.name,fileInfo.type,fileInfo.size,file.path], function(err, rows, fields){
                    if (err) return he.db_error(handler.res, err);
                    if (!rows.insertId)
                        return he.internal_server_error(handler.res);
                    /* --- 
                    even though row id of file is now available we likely can't send it as part of the response to the client. the client
                    has likely gotten the HTTP response before this DB response handler was invoked
                    --- */
                    sql = "INSERT INTO file_refs(ref_table,ref_id,created_at,updated_at,media_file_id) VALUES (?,?,NOW(),NOW(),?),(?,?,NOW(),NOW(),?);";
                    fu.db.query(sql, ['conferences',conference_id,rows.insertId,'users',user_id,rows.insertId], function(err, rows, fields){
                        if (err) return he.db_error(handler.res, err);
                        if (rows.affectedRows!==2)
                            return he.internal_server_error(handler.res);
                        fu.us.send('new_upload');
                        });
                    });
                }
            catch(e) { console.log(e.stack); }
        }).on('aborted', function () {
            try {
                tmpFiles.forEach(function (file) {
                    fs.unlink(file);
                    });
                }
            catch(e) { console.log(e.stack); }
        }).on('error', function (e) {
            try { console.log(e); }
            catch(e) { console.log(e.stack); }
        }).on('progress', function (bytesReceived, bytesExpected) {
            try {
                if (bytesReceived > fu.options.maxPostSize) {
                    handler.req.connection.destroy();
                    }
                }
            catch(e) { console.log(e.stack); }
        }).on('end', finish).parse(handler.req);
    };
    UploadHandler.prototype.destroy = function (fu) {
        var handler = this,
            fileName;
        if (handler.req.url.slice(0, fu.options.uploadUrl.length) === fu.options.uploadUrl) {
            fileName = path.basename(decodeURIComponent(handler.req.url));
            if (fileName[0] !== '.') {
                fs.unlink(fu.options.uploadDir + '/' + fileName, function (ex) {
                    Object.keys(fu.options.imageVersions).forEach(function (version) {
                        fs.unlink(fu.options.uploadDir + '/' + version + '/' + fileName);
                    });
                    handler.callback({success: !ex});
                });
                return;
            }
        }
        handler.callback({success: false});
    };

