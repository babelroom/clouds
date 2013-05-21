(function() {
    function SIO() {
        this._socket = null;
        this.options = null;
        }

    SIO.prototype.init = function(options) {
        this.options = options;
        return this;
        }

    SIO.prototype.connect = function(url, fn) {
        var _this = this;
        if (typeof(io)==="undefined")
            fn('socket io not present or not initialized');
        else if (!(this._socket = io.connect(url/*, options */)))
            fn('socket io error connecting to ['+url+']');
        else {
            this._socket.on('error', function(e){fn(e);});
            this._socket.on('connect', function(){fn(null);});
            }
        return this;
        }

    SIO.prototype.add_conference_credential = function(path, token, fn) {
        if (!this._socket)
            return fn('Not connected');
        this._socket.emit('br_add_conference_credential', JSON.stringify({path: path, token: token}), function(data){
            if (!data) return fn('unexpected null response');
            if (data.error || !data.data) return fn(data.error || 'unexpected null data',null);
            fn(null,data.data);
            });
        }

/*
    SIO.prototype.old_attach = function(conference_id, connection_salt, user_id, fn) {
        if (!this._socket)
            return fn('Not connected');
        this._socket.on('message', function (data) {
            fn(null,data);
            });
        this._socket.send(conference_id + '?ld=' + connection_salt + '-' + user_id);
        }
*/

    SIO.prototype.attach = function(conference_id, connection_salt, user_id, fn) {
        if (!this._socket)
            return fn('Not connected');
        this._socket.on('message', function (data) {
            fn(null,data);
            });
        this._socket.emit('br_attach', conference_id + '?ld=' + connection_salt + '-' + user_id, function(data){
            data || fn('Error attaching');
            });
        }

/*
    SIO.prototype.old_put = function(queue, data, fn) {
        if (!this._socket)
            return fn('Not connected');
        this._socket.emit('br_old_put', JSON.stringify({queue: queue, data: data}));
        fn(null);
        }
*/

    SIO.prototype.put = function(data, fn) {
        if (!this._socket)
            return fn('Not connected');
        this._socket.emit('br_put', JSON.stringify(data));
        fn(null);
        }

    SIO.prototype.api_call = function(data, fn) {
        if (!this._socket)
            fn('Not connected');
        else {
            this._socket.emit('br_api', data, function(result){
                fn(result?null:'Error response from server',result);
                });
            }
        return this;
        }

    SIO.prototype.destroy = function() {
        if (this._socket)
            this._socket.disconnect();
        this._socket = null;
        return this;
        }

    /* --- */
    window.BR.SIO = function(){return (typeof(io['connect'])==="undefined") ?/* no socket.io */null : new SIO();}
})();

