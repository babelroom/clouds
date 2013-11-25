var he = require('./http_errors')
    , routes = require('./AUTO_routes')

var AutoAPI = function(sessionManager, dbManager, udpSender) {
    this.sessionManager = sessionManager;
    this.db = dbManager;
    this.us = udpSender;
}

/* --- utils --- */
function adjusted_cols(f) {
    rc = f.rec.cols;
    if (typeof(f.req.query.c)==="undefined")
        return rc;
    var qa = f.req.query.c.split(',');
    var qh = {};
    var want_count = 0;
    var m;
    for(var i in qa) {
        if ((m=qa[i].match(/^([^=]*)=(.*)$/)))
            qh[m[1]] = m[2];
        else
            qh[qa[i]] = true;
        want_count++;
        }
    qa = [];
    for(var i in rc)
        if (qh[rc[i]])
            qa.push(rc[i]);
    if (want_count!=qa.length)  // requested a non-existant column
        return null;
    return qa;
}

/* --- permission checks returns whether or not request was handled --- */
function perm_the_same_user(f) {
    f.self.sessionManager.expect_uid(f.req,f.rest.id,function(uid, code){
        if (uid<=0) {
            console.log("403 reason: ", uid);
            return he.code(f.res, code);
            }
        f.perm = {uid: uid};
        f.rec.dbfn(f);
        });
}
function perm_valid_user(f) {
    f.self.sessionManager.uid_from_req2(f.req,function(uid, code){
        if (uid<=0) {
            console.log("403 reason: ", uid);
            return he.code(f.res, code);
            }
        f.perm = {uid: uid};
        f.rec.dbfn(f);
        });
}
function _is_conference_owner(f,uid,fn_pass,fn_fail) {
    var sql = "SELECT id FROM conferences WHERE id=? AND owner_id=? AND is_deleted IS NULL";
    f.self.db.query(sql, [f.rest.id,uid], function(err, rows, fields){
        if (err) return he.db_error(f.res, err, sql);
        if (!rows.length)
            return fn_fail ? fn_fail() : he.forbidden(f.res);
        fn_pass();
        });
}
function _is_conference_participant(f,uid,mustBeHost,fn_pass,fn_fail) {
    var sql = "SELECT i.id FROM conferences c, invitations i WHERE c.id=? AND i.user_id=? AND c.is_deleted IS NULL AND i.conference_id=c.id AND i.is_deleted IS NULL";
    if (mustBeHost) sql+= " AND i.role='Host'";
    f.self.db.query(sql, [f.rest.id,uid], function(err, rows, fields){
        if (err) return he.db_error(f.res, err, sql);
        if (!rows.length)
            return fn_fail ? fn_fail() : he.forbidden(f.res);
        fn_pass();
        });
}
function _perm_conference_owner_or_participant(f,mustBeHost) {
    f.self.sessionManager.uid_from_req2(f.req,function(uid, code){
        if (uid<=0) {
            console.log("403 reason: ", uid);
            return he.code(f.res, code);
            }
        function permitted() {
            f.perm = {uid: uid};
            f.rec.dbfn(f);
            }
        _is_conference_owner(f,uid,permitted,function(){
            _is_conference_participant(f,uid,mustBeHost,permitted,null);
            });
        });
}
function perm_conference_owner_or_participant(f) { return _perm_conference_owner_or_participant(f, false); }
function perm_conference_owner_or_host(f) { return _perm_conference_owner_or_participant(f, true); }
function do_end(f) {
    if (f.rec.flags.udpmsg && f.self.us)
        f.self.us.send(f.rec.flags.udpmsg);
    f.res.end()
}

/* --- db queries --- */
function db_1_by_pk(f)
{
    var want_cols = adjusted_cols(f);
    if (!want_cols)
        return he.bad(f.res,'Illegal columns');
    var sql = "SELECT "+want_cols.join(',')+" FROM `"+f.rest.model+"` WHERE id = ?";
    if (f.rec.flags && f.rec.flags.not_deleted)
        sql += " AND is_deleted IS NULL";
    sql += " LIMIT 1";
    f.self.db.query(sql, [f.rest.id], function(err, rows, fields){
        if (err)
            return he.db_error(f.res, err, sql);
        var data = {};
        if (!rows.length)
            return he.not_found(f.res);
        if (rows.length==1) {
            for(var i=0; i<want_cols.length; i++) {
                data[want_cols[i]] = rows[0][want_cols[i]];
                }
            }
        f.res.send(JSON.stringify({data: data}));
        do_end(f);
        });
}

function _set_cols(f, cols, vals)
{
    var ac = {}
    for(var c in f.rec.cols)
        ac[f.rec.cols[c]]=true;
    for(var k in f.req.body)
        if (f.req.body.hasOwnProperty(k)) {
            if (!ac[k]) {
                console.log('Illegal column: '+k);
                he.bad(f.res, 'Illegal columns');     /* column not allowed */
                return false;
                }
            cols.push("`"+k+"`");
            vals.push(f.req.body[k]);
            }
    if (cols.length!=cols.length) {
        console.log('Columns names to values mismatch');
        he.internal_server_error(f.res);
        return false;
        }
    return true;
}

function db_create(f)
{
    var cols = [];
    var vals = [];
    if (!_set_cols(f, cols, vals))
        return /* http error already set */;
    if (f.rec.flags && f.rec.flags.insert_uid_as) {
        cols.unshift('`'+f.rec.flags.insert_uid_as+'`');
        vals.unshift(f.perm.uid);
        }
    var sql = "INSERT INTO `"+f.rest.model+"` (";
    for(var i=0; i<cols.length; i++) {
        sql += cols[i] + ',';
        cols[i] = '?';
        }
    /* obviously this is only going to work for conferences --- adapt when we change to that */
    sql += "`account_id`,`schedule`,`created_at`,`updated_at`) VALUES (";
    cols.push("(SELECT `id` FROM `accounts` WHERE `owner_id` = " + f.perm.uid + ")");
    cols.push("'s'");
    cols.push('NOW()');
    cols.push('NOW()');
    sql += cols.join(',')+")";
    f.self.db.query(sql, vals, function(err, rows, fields){
        if (err)
            return he.db_error(f.res, err, sql);
        if (!rows.affectedRows)
            return he.internal_server_error(f.res);
/* ref:
console.log(rows);
{ fieldCount: 0,
  affectedRows: 1,
  insertId: 37,
  serverStatus: 2,
  warningCount: 0,
  message: '',
  changedRows: 0 }
console.log(fields);
undefined
*/
//        var data = {id: rows.insertId};
        f.res.setHeader('Location', '/' + f.rest.model + '/' + rows.insertId);  // need absolute?
        f.res.statusCode = 201;     /* created */
        f.res.send(JSON.stringify({data: {id: rows.insertId}}));
        do_end(f);
        });
}

function db_update_by_pk(f)
{
    var cols = [];
    var vals = [];
    if (!_set_cols(f, cols, vals))
        return /* http error already set */;
    if (!cols.length) {
        console.log('No columns');
        he.bad(f.res);
        return ;
        }
    for(var i=0; i<cols.length; i++)
        cols[i] += '=?';
    var sql = "UPDATE `"+f.rest.model+"` SET updated_at=NOW(), ";
    sql += cols.join(', ')+" WHERE id = ?";
    vals.push(f.rest.id);
    f.self.db.query(sql, vals, function(err, rows, fields){
        if (err)
            return he.db_error(f.res, err, sql);
        if (!rows.affectedRows)
            return he.not_found(f.res);
/* ref:
console.log(err,rows,fields); -->
null { fieldCount: 0,
  affectedRows: 1,
  insertId: 0,
  serverStatus: 2,
  warningCount: 0,
  message: '(Rows matched: 1  Changed: 1  Warnings: 0',
  changedRows: 1 } undefined
null { fieldCount: 0,
  affectedRows: 1,
  insertId: 0,
  serverStatus: 2,
  warningCount: 0,
  message: '(Rows matched: 1  Changed: 0  Warnings: 0',
  changedRows: 0 } undefined
*/
        f.res.send({});
        do_end(f);
        });
}

function db_set_deleted_flag_by_pk(f)
{
    var sql = "UPDATE `"+f.rest.model+"` SET `updated_at`=NOW(), `is_deleted`=1 WHERE `is_deleted` IS NULL AND `id`=?";
    f.self.db.query(sql, [f.rest.id], function(err, rows, fields){
        if (err)
            return he.db_error(f.res, err, sql);
        if (!rows.affectedRows)
            return he.not_found(f.res);
/* ref:
console.log(err,rows,fields);
null { fieldCount: 0,
  affectedRows: 1,
  insertId: 0,
  serverStatus: 2,
  warningCount: 0,
  message: '(Rows matched: 1  Changed: 1  Warnings: 0',
  changedRows: 1 } undefined
*/
        f.res.send({});
        do_end(f);
        });
}

module.exports = AutoAPI;

var _default_rgx_key = {verb: 1, model: 2, id: 3}; 
/*var routes = [
{rgx: /(GET):\/(users)\/(\d+)$/i, rgx_key: _default_rgx_key, permfn: perm_the_same_user, dbfn: db_1_by_pk, cols: ["name"] },
{rgx: /(GET):\/(conferences)\/(\d+)$/i, rgx_key: _default_rgx_key, permfn: perm_conference_owner_or_host, dbfn: db_1_by_pk, cols: ["name","access_config"] },
]*/
/* now fixup those routes... (convert js string into js code) */
for(var r in routes)
    for(var idx in routes[r])
        if (routes[r].hasOwnProperty(idx)) {
            if (idx==="rgx_key" || idx==="permfn" || idx==="dbfn")
                routes[r][idx] = eval(routes[r][idx]);
            } 

AutoAPI.prototype = {

    request: function(req, res) {
        var f = {
            self: this,
            req: req,
            res: res,
            input: req.method + ':' + req.params[0],
            rest: {}
            }
        for(i=0; i<routes.length; i++) {
            f.rec = routes[i];
            if ((f.match=f.rec.rgx.exec(f.input))!==null) {
                for(var idx in f.rec.rgx_key)   /* copy over keys */
                    if (f.rec.rgx_key.hasOwnProperty(idx))
                        f.rest[idx] = f.match[f.rec.rgx_key[idx]];
                if (f.rec.permfn)
                    f.rec.permfn(f);
                else
                    f.rec.dbfn(f);
                return;
                }
            }
        he.not_found(res);
        }
}

