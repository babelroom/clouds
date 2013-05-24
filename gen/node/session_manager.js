
var crypto = require('crypto')
    , he = require('./http_errors')
    , CryptUtils = require('./crypt_utils')
    ;

var SessionManager = function(config, dbManager) {
    /* config */
    this.cu = new CryptUtils(config);
    this.key = 'brv1'
    this.secret = config.secret;
    this.path = '/';
    this.domain = undefined;
    this.secure = false;
    this.httponly = false;
    if (config.session_manager) {
        if (config.session_manager.key) this.key = config.session_manager.key;
        if (config.session_manager.path) this.path = config.session_manager.path;
        if (config.session_manager.domain) this.domain = config.session_manager.domain;
        if (typeof config.session_manager.secure != 'undefined') this.secure = config.session_manager.secure;
        if (typeof config.session_manager.httponly != 'undefined') this.httponly = config.session_manager.httponly;
        }

    /* db */
    this.db = dbManager;
}
module.exports = SessionManager;

function signature(val, secret)
{
  return crypto
    .createHmac('sha1', secret)
    .update(val)
    .digest('hex');
}

/*
    so the hack here is to deal with the rails session which has used their hokey Marshal.load()/dump() serialization ....
4
8 <-- initial record -- probably version stamp
{ <--- starts a hash
x22 (34) <--- starts a string

lengths (or number of objects)
===
0 === none, 0
1-5 == dunno
*/ var LEN_ADJ=(5+5); /*
6+ -- length+5 (i.e. 6=1, 12=x11

34 <--- string?
... (total length)
data
0
irb(main):090:0> Marshal.dump({:user=>"user:222"}).unpack('C*').map {|e| e.to_s 16}
=> ["4", "8", "7b", "6", "3a", "9", "75", "73", "65", "72", "22", "d", "75", "73", "65", "72", "3a", "32", "32", "32"]
*/
SessionManager.prototype = {
    _uid_from_rails: function(hash) {
        if (!this.key || !this.secret)
            return -1;
        var cookie = hash[this.key] || '';
        var vals = cookie.split('--',2);
        if (vals.length!=2)
            return -2;
        var our_signature = signature(vals[0], this.secret);
        if (our_signature != vals[1]) 
            return -3;
        if (typeof vals[0] != 'string')
            return -4;
        var data = (new Buffer(vals[0], 'base64').toString('binary'));
        var match=/\x3a\x09\x75\x73\x65\x72\x22(.|\x0d)\x75\x73\x65\x72\x3a(.*)/.exec(data); // see above notes on rails session
        if (!match)
            return -5;
        var len_char = match[1].charCodeAt(0);
        /* --- a different way of doing it -- all because js regex dot (.) doesn't match some chars --- var idx = data.indexOf('\x3a\x09\x75\x73\x65\x72\x22');
        if (idx==-1)
            return -5;
        if (data.substr(idx+8,5)!=='\x75\x73\x65\x72\x3a')
            return -6;
        var len_char = data.charCodeAt(idx+7); */
        var len = len_char - LEN_ADJ;
        // max 64-bit # == 18446744073709551615
        if (len<1 || len>20)
            return -7;
        if (match[2].length<len)
            return -8;
        data = parseInt(match[2].substr(0,len), 10) || -1;
        if (data<=0)
            return -9;
        return data;
        },

    _uid_from_qs_or_cookie: function(req) {
        /* easter */ 
        if ('u' in req.query) {
            if (req.query.u.match(/^[1-9]\d*$/))
                return parseInt(req.query.u, 10) || -1;
            return -1;
            }
        /* egg */
        return this._uid_from_rails(req.cookies);
        },

    _mk_cookie: function(val) {
        if (!this.key)
            return null;
        var val = [this.key + '=' + val];
        if (this.domain)
            val.push('domain=' + this.domain);
        if (this.path) 
            val.push('path=' + this.path);
        if (this.secure) 
            val.push('Secure');
        if (this.httponly) 
            val.push('HttpOnly');
        return val.join('; ');
        },

    set_rails_uid: function(res, uid) {
        if (!this.secret)
            return false;
        if (uid<=0)
            return false;   /* just won't work */
        var val = uid.toString();
        if (val.length>20)
            return false;
        val = '\x04\x08\x7b\x06\x3a\x09\x75\x73\x65\x72\x22' + String.fromCharCode(val.length+LEN_ADJ) + '\x75\x73\x65\x72\x3a' + val;   // see above notes on rails session
        val = (new Buffer(val).toString('base64')).toString();
        val += '--' + signature(val, this.secret);
        val = this._mk_cookie(val);
        if (val === null)
            return false;
        res.header('Set-Cookie', val);
        return true;
        },

    delete_rails: function(res) {
        var val = this._mk_cookie('');
        if (val === null)
            return false;
        val += '; expires=Thu, 23-Feb-2012 15:00:00 GMT';
        res.header('Set-Cookie', val);
        return true;
        },

    uid_from_req: function(req) {
        return this._uid_from_qs_or_cookie(req);
        },

    _db_confirm_api_key: function(uid,api_key,fn) {
        this.db.query("SELECT id FROM users WHERE id = ? AND api_key = ?", [uid, api_key], function(err, rows, fields){
            if (err) {
                console.log('DB error validating REST api_key', err);
                return fn(-10,500);
                }
            if (rows.length!==1) {
                console.log('Invalid api_key, user', api_key, uid);
                return fn(-11,403);
                }
            return fn(uid);
            });
        },

    uid_from_req2: function(req,fn) {
        var uid = this._uid_from_qs_or_cookie(req);
        if (uid>0)
            return fn(uid);
        var api_key = req.user; /* express.basicAuth() will have read this from the Authentication header */
        if (!api_key)
            return fn(-20,401);
        /* note: 
        it might make sense to skip decryption here completely. Add a DB index to users.api_key then lookup the user
        it by api_key, leave api_key opaque ...
        but then again we do have the expect_uid() function to help in a lot of cases ...
        */
        var decoded = this.cu.decrypt(api_key);
        var match = /^.+:([1-9a-f][0-9a-f]*):.+$/i.exec(decoded);
        if (!match)
            return fn(-21,403);
        try { uid = parseInt(match[1], 16); }
        catch(e) {
            console.log('Error parsing hex uid',e);
            return fn(-22,500);
            }
        if (!uid)
            return fn(-23,400);
        this._db_confirm_api_key(uid, api_key, fn);
        },

    expect_uid: function(req,id,fn) {     /* we can bypass decryption of api_key by a straight DB lookup if we know what the id must be */
        if (typeof(id)!=="number")
            id = parseInt(id,10) || -1;
        if (id<=0)
            return fn(-30,500);
        var uid = this._uid_from_qs_or_cookie(req);
        if (uid>0)
            return fn((uid===id)?uid:-31,403);
        var api_key = req.user; /* express.basicAuth() will have read this from the Authentication header */
        if (!api_key)
            return fn(-32,401);
        this._db_confirm_api_key(id, api_key, fn);
        },
}

