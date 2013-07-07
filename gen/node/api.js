
var     SessionManager = require('./session_manager')
    ,   AutoAPI = require('./auto_api')
    ,   DBManager = require('./db_manager')
    ,   crypto = require('crypto')
    ,   he = require('./http_errors')
    ,   version_stamp = require('./AUTO_version')
    ;

var API = function(config) {
    this.db = new DBManager(config);
    this.sessionManager = new SessionManager(config, this.db);
    this.autoAPI = new AutoAPI(this.sessionManager, this.db);
}

/* --- this was only an example -- remove it 
..//++apiary--
--
Authentication
APIs for authentication
--
POST signup
> Content-Type: application/json; charset=utf-8
{}
< 200
< Content-Type: application/json; charset=utf-8
{}

..//++apiary--
function signup(self, req, res, match, opts)
{
    self.db.query("INSERT INTO my.users (name) VALUES ("+self.e(req.body.name)+")", [], function(err, rows, fields){
        if (err) return he.db_error(res, err);
        res.send(rows);     // TMP todo -- is this wise?
        res.end();
        });
}

*/
//++apiary--
Retrieve user data associated with active cookie session. The empty set is returned if there is no valid active cookie session.
GET login
< 200
< Content-Type: application/json; charset=utf-8
{}
+++++
< 200
< Content-Type: application/json; charset=utf-8
{"user": {"id":3, "email_address":"apitest@example.com", "email":"apitest@example.com", "name":"API", "last_name":"Test"}}

//++apiary--
function get_current_user(self, req, res, match, opts)
{
    var uid = self.sessionManager.uid_from_req(req);
    if (uid<=0) /* no session */
        res.send('{}');
    else 
        self.db.query("SELECT id, email_address, email, name, last_name FROM users WHERE id = " + self.e(uid), [], function(err, rows, fields){
            if (err) return he.db_error(res, err);
            if (rows.length==1)
                res.send({user: {id: rows[0].id, email_address: rows[0].email_address, email: rows[0].email, name: rows[0].name, last_name: rows[0].last_name}});
            else {
                /* ephemeral use was deleted... */
                res.send('{}');
                }
            res.end();
            });
}

//++apiary--
Login. If successful set a new cookie session.
POST login
> Content-Type: application/json; charset=utf-8
{"login":"apitest@example.com", "password":"default"}
< 200
< Content-Type: application/json; charset=utf-8
{"user": {"id":3, "email_address":"apitest@example.com", "email":"apitest@example.com", "name":"API", "last_name":"Test"}}
+++++
< 200
< Content-Type: application/json; charset=utf-8
{}

//++apiary--
function _login(self, req, res, match, opts)
{
    self.db.query("SELECT id, crypted_password, salt, email_address, email, name, last_name FROM users WHERE email_address="+self.e(req.body.login), [], function(err, rows, fields){
        if (err) return he.db_error(res, err);
        // Digest::SHA1.hexdigest("--#{salt}--#{password}--") -- from ruby/hobo
        var i;
        var result = {};
        for(i=0; i<rows.length; i++) {
            row = rows[i];
            try {
                if ( crypto.createHash('sha1').update('--'+row.salt+'--'+req.body.password+'--').digest('hex') == row.crypted_password ) {
                    if (self.sessionManager.set_rails_uid(res, row.id))
                        result = {user: {id: row.id, email_address: row.email_address, email: row.email, name: row.name, last_name: row.last_name}};
                    else 
                        return he.internal_server_error(res);
                    break;
                    }
                }
            catch(e) { console.log(e); }
            }
if (!result.user) req.body._success_url=req.body._failure_url;    // hack ......... TODO tmp pending cleanup of error handing functions
        he.ok(req, res, result);
        });
}

function _login_by_token(self, req, res, match, opts)
{
    var sql = "SELECT t.user_id, u.email_address, u.email, u.name, u.last_name, t.id FROM users u, tokens t  WHERE u.id=? AND u.id=t.user_id AND t.link_key=? AND t.template='ephemeral_once' AND (t.expires>NOW() OR t.expires IS NULL) AND t.is_deleted IS NULL";
    var token_parts = req.body.token.split(',',2);
    self.db.query(sql, [token_parts[0], token_parts[1]], function(err, rows, fields){
        if (err) return he.db_error(res, err);
        if (rows.length!==1) return he.internal_server_error(res);
        var row = rows[0];
        result = {user: {id: row.user_id, email_address: row.email_address, email: row.email, name: row.name, last_name: row.last_name}};
        /* this is how we would fake it: -- for reference
        self.db.query("UPDATE tokens SET updated_at=NOW() WHERE id=?", [row.id], function(err, rows, fields){ */
        self.db.query("UPDATE tokens SET updated_at=NOW(), is_deleted=1 WHERE id=?", [row.id], function(err, rows, fields){
            if (err) return he.db_error(res, err);
            if (rows.affectedRows!==1) return he.internal_server_error(res);
            if (!self.sessionManager.set_rails_uid(res, row.user_id))
                return he.internal_server_error(res);
            //_maybe_redirect(req, res, result);
            he.ok(req, res, result);
            });
        });
}

function login(self, req, res, match, opts)
{
    if (req.body.login && req.body.password)
        return _login(self, req, res, match, opts);
    else if (req.body.token)
        return _login_by_token(self, req, res, match, opts);
    else 
        return he.bad(res);
}

//++apiary--
Logout. Destroy the currently active cookie session
DELETE login
< 200
< Content-Type: application/json; charset=utf-8
{}

Logout. Synonymous with DELETE login
POST logout
< 200
< Content-Type: application/json; charset=utf-8
{}

//++apiary--
function logout(self, req, res, match, opts)
{
    if (!self.sessionManager.delete_rails(res))
        return he.internal_server_error(res);
    else
        //return _maybe_redirect(req, res, '{}');
        return he.ok(req, res, {});
}

var db_cols = [
    ['u.id', 'user_id'],
    ['u.email_address', 'email_address'],
    ['u.email', 'email'],
    ['u.name', 'first_name'],
    ['u.last_name', 'last_name'],
    ['c.id', 'conference_id'],
    ['c.name', 'conference_name'],
    ['c.config', 'conference_config'],
    ['c.introduction', 'conference_introduction'],
    ['c.uri', 'conference_uri'],
    ['c.access_config', 'conference_access_config'],
    ['c.skin_id', 'conference_skin_id'],
    ['i.id', 'invitation_id'],
    ['i.pin', 'pin'],
    ['i.role', 'role'],
    ['i.dialin', 'myAccessInfo'],
    ];
var db_cols_sql = null;
//++apiary--
Retrieve the superset of context for the currently logged in user, the specified conference and any associated invitation.
The conference uri is appended to the end of the REST resource path /api/v1/invitation
GET invitation/apitest
> Authorization: Basic N2NiNTI0ZmI2NGViNGUyNmQxYjIzM2QyZjI5M2QxMGM6
< 200
< Content-Type: application/json; charset=utf-8
{"data": {
    "user_id":3,
    "email_address":"apitest@example.com",
    "email":"apitest@example.com",
    "first_name":"API",
    "last_name":"Test",
    "conference_id":3,
    "conference_name":"API Test Conference",
    "conference_config":"<internal data>",
    "conference_introduction":"API Test Conference",
    "conference_uri":"apitest",
    "conference_access_config":null,
    "conference_skin_id":1,
    "invitation_id":2,
    "pin":"444444",
    "myAccessInfo":"<internal data>",
    "connection_salt":"<internal>",
    "user_name":"API Test",
    "is_host":true,
    "is_live":false,
    "conference_estream_id":"<internal>"
    }
}

//++apiary--
function invitation(self, req, res, match, opts)
{
//console.log('>> ' + new Date().getTime());
    var uid = self.sessionManager.uid_from_req(req);
    if (uid<0) /* no session, no problem */ 
        uid = 0;    /* set uid to 0 so we get NULL for the user */
        //return he.forbidden(res)
    if (!db_cols_sql) {
        var a = [];
        for(var i=0; i<db_cols.length; i++)
            a.push(db_cols[i][0] + ' AS ' + db_cols[i][1]);
        db_cols_sql = a.join(', ');
        }
/* --- always get 1 row with or without any of user, conference and invitation data, example:
   ---
select u.id as user, c.id as conference, i.id as invitation
FROM (SELECT 42 AS badass FROM dual) AS hack
    left outer join users u on u.id = 371
    left outer join (
    conferences c left outer join invitations i
        ON i.conference_id = c.id and i.user_id = 371 and i.is_deleted IS NULL
    ) on c.uri = 'friday' AND c.is_deleted IS NULL;

*/
/*
    var suid = self.e(uid), sql = "SELECT "+db_cols_sql+" \
FROM (SELECT 42 AS badass FROM dual) AS hack\
    LEFT OUTER JOIN users u ON u.id = "+suid+"\
    LEFT OUTER JOIN (\
    conferences c LEFT OUTER JOIN (\
        invitations i INNER JOIN users u2 ON i.user_id = u2.id AND u2.id = "+suid+"\
        ) ON i.conference_id = c.id\
    ) ON "; */
    var suid = self.e(uid), sql = "SELECT "+db_cols_sql+" \
FROM (SELECT 42 AS badass FROM dual) AS hack\
    LEFT OUTER JOIN users u ON u.id = "+suid+"\
    LEFT OUTER JOIN (\
    conferences c LEFT OUTER JOIN invitations i \
        ON i.conference_id = c.id AND i.user_id = "+suid+" AND i.is_deleted IS NULL \
    ) ON c.is_deleted IS NULL AND ";
    if (/^(?:i|byid)\/(\d+)$/.exec(match[1]))
        sql += 'c.id=' + RegExp.$1;
    else 
        sql += 'c.uri=' + self.e(match[1]);
    self.db.query(sql, [], function(err, rows, fields){
        if (err) return he.db_error(res, err, sql);
/*
        if (rows.length<1)                        /* because we should always get exactly 1 row *./
So this was kicking out where we pointed at a new environment with old session, it confused and created multiple invites for same
user and conference -- question: how could it have created multople invites??? 

*/
        if (rows.length!==1)                        /* because we should always get exactly 1 row */
            return he.internal_server_error(res);
/*
        if (rows.length==0) {   /* perhaps send 404 if conference does not exist vs. data: null if no invitation? *./
            res.send(JSON.stringify({data: null}));
            res.end();
            return;
            }
*/
        data = [];
        var len = fields.length, row = rows[0];
        for(var i=0; i<fields.length; i++)
            data.push([fields[i].name, row[fields[i].name]]);
        /* extra *special* stuff */
        var a='', l=10, b = crypto.randomBytes(l);
        for(var i=0; i<l; i++)
            a += ('0'+((b[i] & 0xff).toString(16))).substr(-2);
        data.push(['connection_salt', a]);
        data.push(['server_version', JSON.stringify(_version())]);
        //res.send({data: data}); -- don't do this; express "helps" with ETag and other _--_
        obj = {};
        for(var i=0; i<data.length; i++)
            obj[data[i][0]] = data[i][1];
        obj.user_name = obj.first_name?(obj.first_name+(obj.last_name?(' '+obj.last_name):'')):(obj.last_name||'')  /* happy that this is one of the best ways to do this */
        obj.is_host = (obj.role=='Host'); //-- now client reads this from stream -- still sent it as initial value, useful for say locking out non-hosts right off the bat
        delete obj.role;   /* not needed for client */
        obj.is_live = false;    /* set to true on client once it's caught up on stream history (when it sees it's only new connection id) */
        try {
            if (obj.conference_config) {
                obj.conference_estream_id = obj.conference_config.split(',')[0].split('=')[1];
                }
            }
        catch(err) {
            console.log(err);   // TODO tmp. what to do?
            }
        res.send(JSON.stringify({data: obj}));
        res.end();
//console.log('<< ' + new Date().getTime());
        });
}

//++apiary--
Add the current user as a conference participant
The conference uri is appended to the end of the REST resource path /api/v1/add_self
POST add_self/apitest
> Authorization: Basic N2NiNTI0ZmI2NGViNGUyNmQxYjIzM2QyZjI5M2QxMGM6
> Content-Type: application/json; charset=utf-8
{
    "user": {
        "name" => "API",
        "last_name" => "Test",
        "email" => "apitest@example.com",
        "origin_data" => "Origin System Name",
        "origin_id" => 37,
        "phone" => "650.555.1212",
        },
    "invitation": {
        },
    "avatar_url": "http://example.com/path/to/my/avatar"
}
< 200
< Content-Type: application/json; charset=utf-8
{}

Add another user as a conference participant
The conference uri is appended to the end of the REST resource path /api/v1/add_participant
POST add_participant/apitest
> Authorization: Basic N2NiNTI0ZmI2NGViNGUyNmQxYjIzM2QyZjI5M2QxMGM6
> Content-Type: application/json; charset=utf-8
{
    "user": {
        "name" => "API",
        "last_name" => "Test",
        "email" => "apitest@example.com",
        "origin_data" => "Origin System Name",
        "origin_id" => 37,
        "phone" => "650.555.1212",
        },
    "invitation": {
        "role":"Host",
        },
    "avatar_url": "http://example.com/path/to/my/avatar",
    "return_token":true
}
< 200
< Content-Type: application/json; charset=utf-8
{}

//++apiary--
function _enter(self, creating_uid, req, res, match, opts)
{
    /* check conference existance and access */
    var sql = "SELECT c.id, c.access_config, c.owner_id FROM conferences c WHERE is_deleted IS NULL AND ";
    if (/^(?:i|byid)\/(\d+)$/.exec(match[1]))
        sql += 'c.id=' + RegExp.$1;
    else 
        sql += 'c.uri=' + self.e(match[1]);
    self.db.query(sql, [], function(err, rows, fields){
        if (err) return he.db_error(res, err);
        if (rows.length!==1 || !rows[0].id) return he.internal_server_error(res);
        var cid = rows[0].id;
        var owner_id = rows[0].owner_id;
        var resultset = {user: {}}
        function create_invitation(uid) {
            var role = ((req.body.invitation && req.body.invitation.role==='Host' && creating_uid && creating_uid===owner_id)?'Host':null);
            resultset.user.id = uid;
            /* insert invitation */
            self.db.query("INSERT INTO invitations (created_at,updated_at,conference_id,user_id,dialin,role) VALUES (NOW(),NOW(),?,?,'(415) 449 8899',?)", [cid,uid,role], function(err, rows, fields){
                if (err) return he.db_error(res, err);
                if (!rows.insertId) return he.internal_server_error(res);
                var iid = rows.insertId;
                self.db.query("UPDATE pins SET updated_at=NOW(), invitation_id=? WHERE invitation_id IS NULL LIMIT 1", [iid], function(err, rows, fields){
                    if (err) return he.db_error(res, err);
                    if (rows.affectedRows!==1) return he.internal_server_error(res);
// ---- extra query in case we need to get the pin ... do we? -- keep code for ref
//                    self.db.query("SELECT pin FROM pins WHERE invitation_id=?", [iid], function(err, rows, fields){
//                        if (err) return he.db_error(res, err);
//                        if (rows.length!==1) return he.internal_server_error(res);
//                        var pin = rows[0].pin;
//                        self.db.query("UPDATE invitations SET updated_at=NOW(), pin=? WHERE id=?", [pin,iid], function(err, rows, fields){
                        self.db.query("UPDATE invitations SET updated_at=NOW(), pin=(SELECT pin FROM pins WHERE invitation_id=?) WHERE id=?", [iid,iid], function(err, rows, fields){
                            if (err) return he.db_error(res, err);
                            if (rows.affectedRows!==1)
                                return he.internal_server_error(res);
                            /* set uid in cookie or make token */
                            if (opts && opts.no_cookie) {
                                function finish() {
                                    res.send(JSON.stringify(resultset));
                                    res.end();
                                    }
                                if (!req.body.return_token)
                                    return finish();
                                var token = crypto.randomBytes(30).toString('base64').replace(/[^A-Za-z0-9]/g,'J');
                                self.db.query("INSERT INTO tokens (template,link_key,created_at,updated_at,user_id) VALUES (?,?,NOW(),NOW(),?)", ['ephemeral_once',token,uid], function(err, rows, fields){
                                    if (err) return he.db_error(res, err);
                                    if (rows.affectedRows!==1)
                                        return he.internal_server_error(res);
                                    resultset['token'] = uid+','+token;
                                    finish();
                                    });
                                }
                            else {
                                if (!self.sessionManager.set_rails_uid(res, uid))
                                    return he.internal_server_error(res);
                                return he.ok(req, res, resultset);
                                }
                            });
//                        });
                    });
                });
            }
        function continue_with_user(uid) {
            if (!req.body.avatar_url)
                return create_invitation(uid);
            sql = 'INSERT INTO media_files (user_id,upload_url,bucket,created_at,updated_at) VALUES (?,?,"Avatar",NOW(),NOW())';
            self.db.query(sql, [uid,req.body.avatar_url], function(err, rows, fields){
                if (err) return he.db_error(res, err);
                if (!rows.insertId) return he.internal_server_error(res);
                create_invitation(uid);
                });
            }

        if (creating_uid && !(opts && opts.create_separate_user))
            return continue_with_user(creating_uid);
        /* else */
        /* conference needs to be public in order for non-owner & non-host to add self .... TODO tmp */
        /* insert user */
        /* check arguments */
        var u = req.body.user;
        if (!u)
            u = {};
        if (!u.name && req.body.name)   /* why allow either name or user.name? I know there was a good reason for this but I've forgotten ... */
            u.name = req.body.name;
        sql = "INSERT INTO users (`created_at`,`updated_at`";
        var vals = ") VALUES (NOW(),NOW()";
        for(var i in u)
            if (u.hasOwnProperty(i)) {
                if (i in {name:1,last_name:1,email:1,phone:1,origin_data:1,origin_id:1}) {
                    sql += ',`'+i+'`';
                    vals += ','+self.e(u[i]);
                    }
                else
                    return he.bad(res);
                }
        if (!('name' in/* need to check this way b/c of "in" for loop above */u)) { /* make a new name */
            sql += ", `name`";
            vals += ", CONCAT('User #',LPAD(MOD(LAST_INSERT_ID()+1,1000), 3, '0'))";/* User #045 */
            resultset.user.name = '';
            }
        else
            resultset.user.name = u.name;
        sql += vals + ')';
        self.db.query(sql, [], function(err, rows, fields){
            if (err) return he.db_error(res, err);
            if (!rows.insertId) return he.internal_server_error(res);
            continue_with_user(rows.insertId /*uid of new user */);
            });
        });
}
function enter(self, req, res, match, opts)
{
    self.sessionManager.uid_from_req2(req,function(uid,code){
        _enter(self, uid>0?uid:0, req, res, match, opts);
        });
}

/* this facility to be depreciated */
var aq_commands = [
    "0",
    "user/select/SELECT phone FROM users WHERE id = ?",
    "user/sql/UPDATE users SET phone = ? WHERE id = ?",
    "user/update",
    "media_file/select/SELECT * FROM media_files WHERE user_id = ? OR conference_id = ?",
    "invitation/select/SELECT i.pin, i.user_id, u.name, u.last_name, CONCAT(u.name,' ',u.last_name) AS full_name, i.role, u.phone, u.email_address FROM invitations i, users u WHERE i.user_id = u.id AND i.conference_id = ?",
    "user/select/SELECT id FROM users WHERE email_address=? LIMIT 1",
    "skin/select/SELECT id,name,immutable,preview_url FROM skins",            // 7
//                    "skin/sql/INSERT INTO skins (name) VALUES (?)",     // 8
    "skin/insert",     // 8
    "skin/copy",
    "skin/update",                                      // 10 
    "conference/update",                                // 11
//                    "skin/select/SELECT body FROM skins WHERE id = ? -- ignore name param = ?", -- leave as example of using comment for unwanted parameters
    "skin/delete",            // 12
    "skin/select/SELECT id,name,body FROM skins WHERE id=?",
    "media_file/select/SELECT * FROM media_files WHERE ((user_id=? OR conference_id=?) AND slideshow_pages>0)", // AND access permissions ...
// note, no need to exclude 1 or 2 letter words as the length is too short in any case ...
//    "conference/select/SELECT id FROM conferences WHERE uri=:uri UNION SELECT 0 FROM DUAL WHERE :uri IN (\
    "conference/select/SELECT id FROM conferences WHERE uri=? UNION SELECT 0 FROM DUAL WHERE ? IN (\
'login','logout','plugin','home','admin2548','admin_set_current_user2548','byid',\
'users',\
'blog','support','legal','contact','info','demos','faq','pricing','tour','wp-content','wp-admin','wp-includes',\
'sex','fuck','god',\
'') LIMIT 1",
];
function aq(self, req, res, match, opts)
{
    var uid = self.sessionManager.uid_from_req(req); /* TODO .. at least for present make sure they are logged in */
    if (uid<=0) /* no session */ 
        return he.forbidden(res)
    var act = -1;
    try { act = parseInt(req.body.act); } catch(e) {}
    if (act<0 || act>=aq_commands.length)
        return he.bad(res);
    act = aq_commands[act].split('/',3);
    if (/^(?:select)/.exec(act[1])) {
        self.db.query(act[2], req.body.args && req.body.args.ah || [], function(err, rows, fields){
            if (err) return he.db_error(res, err, act[2]);
            var data = [];
            for(var i=0; i<rows.length; i++) {
                var record = {};
                record[act[0]] = rows[i];
                data.push(record);
                }
            //res.send(JSON.stringify({data: data}));
            res.send(JSON.stringify(data));
/*
Not implemented
[ 'user', 'update' ]
{ act: '3', args: { f: { phone: '+14157025254' }, id: '2' } }
*/
            res.end();
            });
        }
    else if (act[1]=='update') {
        var sql = "UPDATE " + act[0] + "s SET ";    /* add an 's', i.e. pluralize, hack but works in this constrained case */
        var x = req.body.args.f;
        var a = [];
        for(var y in x) {
            a.push("`" + y + "`=" + self.e(x[y]));
            }
        sql += a.join(', ') + " WHERE `id` = " + self.e(req.body.args.id);
        self.db.query(sql, [], function(err, rows, fields){
            if (err) return he.db_error(res, err, sql);
            res.send('{}');
            res.end();
            });
        }
            //res.send(JSON.stringify({data: data}));
    else {
        console.log('Not implemented');
        console.log(act);
        console.log(req.body);
        return he.not_implemented(res);
        }
/*
    console.log(act);
    /.* kinda leaving off here ... *./
    res.send("{}");
    res.end();
*/
}

//++apiary--
--
Server
APIs for server version and status.
--
Server status. This is mainly for use by automated server monitoring tools.
GET status
< 200
< Content-Type: application/json; charset=utf-8
{
  "status": "OK"
}

//++apiary--
function get_status(self, req, res, match, opts)
{
    /* blunt status -- for use by pingdom et. al. */
    res.send({status: 'OK'});
    res.end();
}

//++apiary--
Server version. 
GET version
< 200
< Content-Type: application/json; charset=utf-8
{
  "major": "2",
  "minor": "37",
  "commit": "201",
  "stamp": "2.37.201"
}

//++apiary--
function _version() 
{
    if (!/^(\d+)\.(\d+)\.(.*)$/.exec(version_stamp))
        return null;
    return {major: RegExp.$1, minor: RegExp.$2, commit: RegExp.$3, stamp: version_stamp};
}
function get_version(self, req, res, match, opts)
{
    var v = _version();
    if (!v)
        return he.internal_server_error(res);
    res.send(v);
    res.end();
}

var routes = [
[/GET:\/status$/i, get_status],
[/GET:\/version$/i, get_version],
[/POST:\/signup\/(.)(.)(.*)$/i, signup],
// -- [/(?:GET|POST):\/current_user\/?(.*)$/i, current_user], // --- preserve useful regex for reference
[/GET:\/login$/i, get_current_user],
[/POST:\/login$/i, login],
[/DELETE:\/login$/i, logout],
[/POST:\/logout$/i, logout],    /* synomym for delete login, easier to read/debug in form */
// -- [/GET:\/country$/i, country],
[/GET:\/invitation\/(.*)$/i, invitation],
[/POST:\/_aq$/i, aq],           /* depreciate soon in preference to specific, secure functions */
// -- [/GET:\/conference_access\/(.*)$/i, conference_access],
[/POST:\/add_self\/(.*)$/i, enter],
[/POST:\/add_participant\/(.*)$/i, enter, {no_cookie: true, create_separate_user:true}],
];


/* write apiary prolog for next (auto) section */
//++apiary--
--
General Purpose Resources
These resources are automatically generated from
[https://github.com/babelroom/clouds/blob/master/gen/schema/main.sch](https://github.com/babelroom/clouds/blob/master/gen/schema/main.sch)
--
//++apiary--


API.prototype = {
    addUseHandlers: function(express, app, options) {
        var self = this;
        function use(fn) { app.use('/api/', fn); }
        use(express.cookieParser());

/* =======================
seems to be  an unresolved issue in express that bad json will cause a stacktrace to be sent to the client (ooch!),
none of the solutions on this thread appear to work ...

http://stackoverflow.com/questions/7478917/catching-illegal-json-post-data-in-express

        app.use(express.bodyParser());
//app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
//app.use(express.errorHandler({ dumpExceptions: false, showStack: false }));
//app.error(function(err,req,res,next) { console.log("ERR"); });
console.log(express.bodyParser());
express.bodyParser.parse['application/json'] = function(data) {
  var result = JSON.parse(data)
  if (typeof result != 'object') {
    throw new Error('Problems parsing JSON')
  }
  return result;
}
//        app.use(express.urlencoded());
======================= */
        use(function(req, res, next){
            /* little hack to solve IE8 XDomainRequest not setting content-type */
            /* what we really need to do is to write a custom middleware for json to also solve the 
            problem that it barfs stack traces down the connection */
            if (!req.headers['content-type'])
                req.headers['content-type'] = 'application/json';
            next();
            });
        use(express.json());
        use(express.urlencoded());      /* TMP todo leave this in temporarily until we yank aq out */
        use(function(req, res, next){
            var mo = req.get('X-HTTP-Method-Override');
            req._method = mo ? mo : req.method;
            next();
            });
        use(express.logger('short'));

        // *** actually we don't use this anymore as (like most express plugins) it's a colorful flavor of crap, i.e. creates 401 if no Authenticate header
        // we use this to set the value of req.user for later use by session utils
/*        app.use(express.basicAuth(function(user, pass){
            return true;
            })); */

        use(function(req, res, next){
            /* most of this copied from: ./node_modules/express/node_modules/connect/lib/middleware/basicAuth.js */
            var a = req.headers.authorization;
            if (!a)
                return next();
            var parts = a.split(' ');
            if (parts.length!==2)
                return next();  // he.bad(req); -- let it wash out ...
            var scheme = parts[0]
                , credentials = new Buffer(parts[1], 'base64').toString()
                , index = credentials.indexOf(':');
            if ('Basic' != scheme)
                return next(); // he.bad(req); -- let it wash out ... 
            if (index<0)
                req.user = credentials;
            else {
                req.user = credentials.slice(0, index);
                req.pass = credentials.slice(index+1);
                }
            next();
            });

        // empty response to top-level 'OK'
/*        app.get('/', function (req, res) {
            res.send('This is not the page you are looking for.');
            res.end();
            });*/
        },

    addHandlers: function(express, app, options) {
        var self = this;
/*
        // blunt status -- for use by pingdom et. al.
        app.get('/api/v1/status', function (req, res) {
            /* put more stuff in here later *./
            res.send('OK');
            res.end();
            });
*/

        /* re: access-control-allow ...
        We allow *everything* ... no restrictions on the api as we just don't know whose webpage    
        will be instigating the request -- we have our security elsewhere, not here
        */
        function access_control_allow_origin(req, res) {
            var origin = req.headers['origin'];
            if (origin) {
                res.setHeader('Access-Control-Allow-Origin', origin);
                res.setHeader('Access-Control-Allow-Credentials', true);
//                res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With'); -- what is this?
                }
            }

        app.options(/^\/api\/v1\/.*/, function(req, res){
            res.setHeader('Access-Control-Allow-Methods', 'GET, PUT, POST, DELETE');  // this is needed
            if (req.headers['access-control-request-headers']) 
                res.setHeader('Access-Control-Allow-Headers', req.headers['access-control-request-headers']);
            access_control_allow_origin(req, res);
            res.end();
            });

        app.all(/^\/api\/v1(\/.*)$/, function(req, res) {
            access_control_allow_origin(req, res);
            var found = false
                , path = req.params[0]
                , input
                , match;
            input = (path==='/_dynform' && req.body._dynform_method && req.body._dynform_path && /^\/api\/v1(\/.*)$/.exec(req.body._dynform_path)) ?
                (req.body._dynform_method + ':' + RegExp.$1) :
                (req._method + ':' + path)
            res.setHeader('Content-Type', 'application/json; charset=utf-8');       /* all responses are json */
            res.setHeader('Cache-Control', 'no-cache, max-age=0, must-revalidate'); /* kill caching */
            for(i=0; i<routes.length && !found; i++) {
                if ((match=routes[i][0].exec(input))!==null) {
                    var opts = {}
                    if (routes[i].length>2) {
                        opts = routes[i][2];
                        }
                    found = true;
                        routes[i][1](self, req, res, match, opts);
                    }
                }
            if (!found)
                return self.autoAPI.request(req, res);
            });
        },

    // private
    e: function(str) {
        return this.db.esc(str);
        },
}

module.exports = API;

