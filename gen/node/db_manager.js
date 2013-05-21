
var     mysql = require('mysql')
    ,   DEFAULT_POOL_SIZE=10
    ,   CONN_PENDING_COUNT=99999999
    ,   he = require('./http_errors')
    ;

var DBManager = function(config) {
    this._db_config = config.mysql;                                                 /* pass options intact (at least for now) */
    this._db_poolsize = this._db_config.poolsize || DEFAULT_POOL_SIZE;
    this._db_pool = [];
    this._db_unconnected_connection = this._createConnection();                     /* this is used to SQL escape strings */
    this._initPool();   /* should this be in a separate init() method? */
}

DBManager.prototype = {

    /* public */
    query: function(sql, values, fn) {
        try {
            var conn = this._getConn(), _this = this;
            conn.query(sql, values, function(e,r,f){
                _this._returnConn(conn);
                try { fn(e,r,f); }
                catch(err) {
                    console.log(err);
                    fn(err);
                    }
                });
            }
        catch(e) {
            fn(e, null, null);
            }
        },

    esc: function(value) {
            return this._db_unconnected_connection.escape(value);
        },

    /* private */
    _createConnection: function() { return mysql.createConnection(this._db_config); },
    _createPoolConnection: function(idx) {
        var _this = this, conn = this._createConnection();
        conn.br_idx = idx;
        conn.br_count = CONN_PENDING_COUNT;
        function _handleDisconnect(connection) {
            connection.on('unhandledError',function(err){ console.log('Unhandled error: ' + err); });
            connection.on('end',function(err){ console.log('end: ' + err); });
            connection.on('error',function(err){
                if (!err.fatal) return;
/*                if (err.code != 'PROTOCOL_CONNECTION_LOST') throw err; */
                console.log('DBManager disconnection: ' + err.stack);
                conn.br_count += CONN_PENDING_COUNT;
                _this._moveDown(conn);
                _this._db_pool[conn.br_idx] = _this._createPoolConnection(conn.br_idx);
                });
            }
        console.log('DBManager connecting...['+idx+']');
        _handleDisconnect(conn);
        conn.connect(function(err){
            if (err) {
                console.log('connect: ['+conn.br_idx+'] '+err);
                conn.br_destroy = true;
                }
            else { 
                conn.br_count -= CONN_PENDING_COUNT;
                _this._moveUp(conn);
                }
            });
        return conn
        },
    _dumpPool: function() {
        var old_count = -1;
        for(var i=0; i<this._db_poolsize; i++) {
            var c = this._db_pool[i];
            if (c.br_count<old_count)
                throw new Error('DBManager pool bad internal ERROR! ['+i+', '+c.br_count+', last('+old_count+')]');
            old_count = c.br_count;
            console.log(c.br_idx+' - '+c.br_count);
            }
        },
    _initPool: function() {
        var self = this;
        console.log('initializing pool of size ['+self._db_poolsize+']');
        for(var i=0; i<self._db_poolsize; i++)
            self._db_pool[i] = self._createPoolConnection(i);
        setInterval(function(){    /* crude, but allows reconnection if DBManager goes away for a longer period */
            for(var i=0; i<self._db_poolsize; i++)
                if (self._db_pool[i].br_destroy)
                    self._db_pool[i] = self._createPoolConnection(i);
            },1000);
        },
    _moveDown: function(conn) {
        var idx;
        for(idx=conn.br_idx+1; idx<this._db_poolsize; idx++)
            if (this._db_pool[idx].br_count>=conn.br_count)
                break;
        if (idx>1) { /* swap only if both entries are not next to each other */
//console.log(">swap: "+idx+", "+conn.br_idx);
            idx--;
            var swp2 = this._db_pool[idx];
            this._db_pool[idx] = conn;
            this._db_pool[conn.br_idx] = swp2;
            swp2.br_idx = conn.br_idx;
            conn.br_idx = idx;
            }
//else console.log("<no swap: "+idx+", "+conn.br_idx);
//        this._dumpPool();
        },
    _moveUp: function(conn) {
        var idx;
        for(idx=conn.br_idx-1; idx>=0; idx--)
            if (this._db_pool[idx].br_count<=conn.br_count)
                break;
        if (idx<(conn.br_idx-1)) { /* swap only if both entries are not next to each other */
//console.log("<swap: "+idx+", "+conn.br_idx);
            idx++;
            var swp2 = this._db_pool[idx];
            this._db_pool[idx] = conn;
            this._db_pool[conn.br_idx] = swp2;
            swp2.br_idx = conn.br_idx;
            conn.br_idx = idx;
            }
//else console.log("<no swap: "+idx+", "+conn.br_idx);
//        this._dumpPool();
        },
    _getConn: function() {
        var conn = this._db_pool[0];
//console.log('>> ' + conn.br_count);
        conn.br_count++;
        this._moveDown(conn);
        return conn;
        },
    _returnConn: function(conn) {
//console.log('<< ' + conn.br_count);
        conn.br_count--;
        this._moveUp(conn);
        }
}

module.exports = DBManager;

