(function(){
    typeof window.BR==="undefined"?window.BR={v1:{}}:typeof window.BR.v1==="undefined"&&(window.BR.v1={});
    window.BR.v1.controllers = {
        chat: {
            _subscribeChat: function() {
                var month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                var n = this._api.notify, _this=this;
                n.subscribe(function(o){
                    var user_id = null, user = '', msg = o.data;
                    if (typeof(msg)==='undefined')
                        return _this.onClear();
                    if (msg.match(/^{/)) {
                        try {
                            var r = JSON.parse(msg);
                            user_id = r.user_id;
                            user = r.user;
                            msg = r.text;
                            if (r.to) /* accomodation for future private chat */
                                return;
                            }
                        catch(e) { return; }
                        }
                    /* depreciate these old encoding formats soon ... */
                    else if (msg.match(/^(\d+)-([^:]*):(.*)$/)) {
                        user_id = RegExp.$1;
                        user = RegExp.$2;
                        msg = RegExp.$3;
                        }
                    else if (msg.match(/^([^:]*):(.*)$/)) {
                        user = RegExp.$1;
                        msg = RegExp.$2;
                        }
                    var avatar = null;
                    if (user_id && n.user_map && n.user_map[user_id] && n.user_map[user_id].avatar_small)
                        avatar = n.user_map[user_id].avatar_small;
                    var msg_top = '<div style="color: #bbb; border: 0; border-top: 1px solid #ddd;">';
                    msg_top += '<div style="float: left; font-weight: bold;">'+user+'</div><div style="float: right;">';
                    var time = '';
                    if (o.ts!==undefined) {
                        var d = new Date;
                        function dmy(d) { return d.getFullYear()+'-'+d.getMonth()+'-'+d.getDate()      +'--'+d.getHours(); }
                        function tme(d) { return d.getTime(); }
                        function time_since_midnight(d) { return (((((d.getHours()*60)+d.getMinutes())*60)+d.getSeconds())*1000)+d.getMilliseconds(); }
                        var today = dmy(d);
                        var time_now = tme(d);
                        var tsm = time_since_midnight(d);
                        d.setTime(o.ts);
                        if (dmy(d)!==today) {
                        if ((time_now - tme(d))<(86400000/* 1000*60*60*12 */+tsm))
                            time += 'Yesterday ';
                        else
                            time += month_names[d.getMonth()] + ' ' + d.getDate() + ' ';
                            }
                        time += d.getHours() + ':' + (d.getMinutes()<10 ? '0' : '') + d.getMinutes();
                        }
                    _this.onMessage({text: msg, time: time, user:user, avatar:avatar, origin_id:undefined});
                    }, 'chat');
/* depreciate soon -- this is the old clear chat format */
                n.subscribe(function(o){
                    switch(o.command) {
                        case 'clearChat':
                            _this.onClear();
                            break;
                        }
                    },'command');
/* end -- depreciate soon */
                },
            _onInit: function() {
                this._subscribeChat();
                },
            onMessage: function(msg) {},
            onClear: function() {},
            sendElement: function(id) {
                var elem = document.getElementById(id);
                if (typeof(elem)==="undefined")
                    return;
                this.sendMessage({text: elem.value}, function(){ elem.value = ''; });
                },
            sendMessage: function(msg, fn) {
                this._api.commands.sendChat(this._api.context.user_id, this._api.context.user_name, msg, fn);
                }
            },
        summary: {
            _onInit: function() {
                var n = this._api.notify, _this=this;
                n.subscribe(function(o){
                    if(o.updated.is_live && _this._api.context.is_live){ _this.onLoad(_this._api.context); }
                    },'room_context');
                },
            onLoad: function(cxt) {}
            },
        participants: {
            count: 0,
            excludeSelf: false,
            _onInit: function() {
                var n = this._api.notify
                    , _this=this
                    , ud=function(id){ if (n.user_map[id]) _this.onUpdate(id, n.user_map[id]); }
                    ;
                
                n.subscribe(function(o){
                    if (_this.excludeSelf && o.id==_this._api.context.user_id)
                        return;
                    switch(o.command) {
                        case 'show':
                            _this.count++;
                            _this.onCountChange(_this.count);
                            ud(o.idx);
                            break;
                        case 'hide':
                            _this.count--;
                            _this.onRemove(o.idx);
                            _this.onCountChange(_this.count);
                            break;
                        /*case 'update':
                            ud(o.idx);
                            break; */
                        }
                    },'box');
                n.subscribe(function(o){
                    if (!_this.excludeSelf || o.id!=_this._api.context.user_id)
                        ud(o.idx);
                    },'users');
                this.onCountChange(0);
                },
            onCountChange: function(newCount) {},
            onUpdate: function(id,user) {},
            onRemove: function(id,user) {}
            },
        privateConference: {
            _haveWebRTC: typeof(wrapRTC)==="undefined" ? false : !!wrapRTC.supported,        /* whether or not webRTC/wraprtc is included and supported */
            _key: null,
            _incoming: [],
            _pc: null,
            _peer: null,
/*            _state: null,
            _indicators: null, */
            _newKey: function() {
                this._key = Math.random().toString(36).substring(2);
                },
            _setPC: function(pc) {
                this._pc = pc;
                for(var i=0; i<this._incoming.length; i++)
                    this._signalIn(this._incoming[i]);
                this._incoming = [];
                },
            _sendAction: function(msg, peer_key) {
                this._api.commands.videoAction('p2p-' + this._key + (peer_key?'-'+peer_key:''), msg);
                },
            _uname: function(id) {
                var n = this._api.notify, u=null;
                if (n && n.user_map && id && n.user_map[id]) 
                    u = n.user_map[id];
                if (u)
                    return (u.name||'') + ((u.name&&u.last_name)?' ':'') + (u.last_name||'');
                },
            _possiblePeerUpdate: function(obj, peer_key) {
                if (!peer_key && this._peer && this._peer.connection_id==obj.connection_id) /* our peer went offline */
                    return this._stop(false);
                if (this._peer && (this._peer.key!=peer_key))
                    return;
                if (obj.data) {
                    /* availability / track info ... */
                    try {
                        var data = JSON.parse(obj.data);
                        /*peerMetadata[peer_key] = obj;
                        if (webrtc_data && webrtc_data.pcs[peer_key])
                            updateMetadata(peer_key); */
                        if (typeof(data.available)!=='undefined')
                            this.onUserStatusUpdate('presence', {id:obj.user_id, connection_id:obj.connection_id, key:peer_key, available: data.available});
                        }
                    catch(e) {}
                    }
                else if (this._peer) {
                    this._stop(false);
                    }
                },
            _preoffer: function(peer_key, msg, obj) {
                if (this._peer)    /* what? */return;
                this._peer = {key: peer_key, connection_id:obj.connection_id, key_at_preoffer:this._key};
                this._sendAction(JSON.stringify({available:false})); /* busy */
//console.log(['_preoffer',peer_key,this,msg,obj]);
                this.onCallStatusUpdate('ringing', {awaiting_permission:false, name:this._uname(obj.user_id)});
                },
            _answer: function(peer_key, msg, obj) {
                var _this = this, call_key = _this._key;
                if (!this._peer)    /* what? */return;
                if (this._peer.key_at_preoffer!=this._key)
                    return this._stop(false);
                if (this.options.stereo)
                    wrapRTC.addStereoToSDP(msg);
                this.onCallStatusUpdate('ringing', {awaiting_permission:true, name:this._uname(obj.user_id)});
                wrapRTC.openWebcam({
//(function foo(obj) {return obj.setStream(null);})({
                    element: _this.localVideo,
                    onSupportFailure: function(msg) { _this._error(call_key, msg); },
                    onError: function(code) {
                        switch(code) {
                            case 1: /* camera / microphone access denied */
                                _this._error(call_key);
                                break;
                            default:
                            }
                        },
                    setStream: function(stream) {
                        if (_this._key!==call_key) return;      /* call cancelled before clicking browser accept */
                        _this.onCallStatusUpdate('ringing', {awaiting_permission:false, name:_this._uname(obj.user_id)});
                        _this._peer.stream = stream;
                        wrapRTC.answer(msg, stream, {
                            //element: _this.localVideo,
                            element: _this.remoteVideo,
                            onError: function(error) { _this._error(call_key, error); },
                            setPC: function(pc) { _this._setPC(pc);},
                            signalOut: function(msg) { _this._sendAction(JSON.stringify(msg), peer_key); },
                            connected: function() { _this.onCallStatusUpdate('connected'); },
                            disconnected: function() { _this._stop(false); }
                            });
                        }
                    });
                },
            _signalIn: function(msg) {
                var _this = this;
//console.log(msg);
                switch(msg.type) {
                    case 'answer':
                        if (true/*webrtc_data.pcs[peer_key]*/) {
                            if (_this.options.stereo)
                                wrapRTC.addStereoToSDP(msg);
                            wrapRTC.setRemoteDescription(_this._pc/*check pc...webrtc_data.pcs[peer_key]*/, msg);
//                            indicators.peerCount++;
//                            opts.updateBroadcasterIndicators(indicators);
//                            peerKeys[peer_connection_id] = peer_key;
                            }
                        break;
                    case 'candidate':
                        if (true/*webrtc_data.pcs[peer_key]*/) {
//                            webrtc_data.candidate_count = webrtc_data.candidate_count + 1;
//                            openingVideo(webrtc_data.candidate_count);
                            wrapRTC.candidate(_this._pc/*check pc...*/, msg);
                            }
                        break;
                    case 'metadata':
                        _this.onCallStatusUpdate('metadata',msg);
                        break;
                    }
                },
            _setupVideo: function() {
                var n = this._api.notify, _this=this;
                this._newKey();
                n.subscribe(function(o){
//if(!o.data) console.log(['video',o,_this]);
                    var sk = o.subkey.split(/-/, 3); // subkeys
                    if (sk.length<1)    /* this is an error */
                        return;
                    var mechanism = sk[0];
                    if (mechanism != 'p2p')
                        return;
                    var from_key = sk[1];
                    var to_key = sk[2];
                    if (to_key) { /* targeted for a specific peer */
                        if (_this._key && to_key==_this._key && typeof(o.data)!=='undefined') {
                            try {
                                var obj = JSON.parse(o.data);
//console.log(obj);
                                if (obj.type==='preoffer')
                                    _this._preoffer(from_key, obj, o);
                                else if (obj.type==='offer')
                                    _this._answer(from_key, obj, o);
                                else if (_this._pc)
                                    _this._signalIn(obj);
                                else
                                    _this._incoming.push(obj);
                                }
                            catch(e) { }
                            }
                        return;
                        }
                    if (o.connection_id!=n.connection_id && from_key.length) {          /* not our own connection */
                        //peer_webcam_onoff(o.connection_id, o.user_id, from_key, o.data);
                        _this._possiblePeerUpdate(o, from_key);
                        }
                    },'video');
                n.subscribe(function(o) {
                    /* user has gone offline, delete any associated video */
                    if (o.command==='del' && o.connection_id!=/*obviously this can't happen but include for completeness*/n.connection_id) {
                        _this._possiblePeerUpdate(o);
                        }
                    },'online');
                n.subscribe(function(o){
                    if(o.updated.is_live && _this._api.context.is_live) {
                        _this._sendAction(JSON.stringify({available:true})); /* advertise our availability */
                        }
                    },'room_context');
                },
            _error: function(original_key, msg) {
                if (this._key===original_key) {    /* call cancelled before clicking browser deny? */
                    if (msg) {
                        if (console && console.log) console.log('WebRTC error ['+msg+']');
                        this.onCallStatusUpdate('error');
                        }
                    else
                        this.onCallStatusUpdate('permission_denied');
                    this._stop(true);
                    }
                },
            _stop: function(delay) {
                this._sendAction(undefined);                           /* signal we are stopping */
                this.onCallStatusUpdate('done', {delay:delay?1500:0}); /* delay long enough to show error msg */
                if (this._pc) {
                    wrapRTC.stopConnection(this._pc);
                    this._pc = null;
                    }
                this._incoming = [];
                this._peer = null;
                this._newKey();                                        /* cycle key */ 
                this._sendAction(JSON.stringify({available:true}));    /* advertise our availability */
                },
            _onInit: function() {
                if (this._haveWebRTC) {
                    this._setupVideo();
                    }
                },
            localVideo: null,
            remoteVideo: null,
            onUserStatusUpdate: function(state, params) {},
            onCallStatusUpdate: function(state, params) {},
            call: function(params) {
                var _this = this, call_key = _this._key;
                if (_this._peer)    /* what? */return;
                _this._peer = {key: params.key, connection_id:params.connection_id};
                _this._sendAction(JSON.stringify({available:false})); /* busy */
                _this._sendAction(JSON.stringify({type:'preoffer'}), _this._peer.key);
                _this.onCallStatusUpdate('calling', {awaiting_permission:true, name:_this._uname(params.id)});
                wrapRTC.openWebcam({
                    element: _this.localVideo,
                    onSupportFailure: function(msg) { _this._error(call_key, msg); },
                    onError: function(code) {
                        switch(code) {
                            case 1: /* camera / microphone access denied */
                                _this._error(call_key);
                                break;
                            default:
                            }
                        },
                    setStream: function(stream) {
                        if (_this._key!==call_key) return;      /* call cancelled before clicking browser accept */
                        _this.onCallStatusUpdate('calling', {awaiting_permission:false, name:_this._uname(params.id)});
                        _this._peer.stream = stream;
                        wrapRTC.callPeer(stream, {
                            element: _this.remoteVideo,
                            onError: function(error) { _this._error(call_key, error); },
                            setPC: function(pc) { _this._setPC(pc);},
                            connected: function() { _this.onCallStatusUpdate('connected'); },
                            disconnected: function() { _this._stop(false); },
                            signalOut: function(msg) { _this._sendAction(JSON.stringify(msg), params.key); }
                            });
                        }
                    });
                },
            control: function(key, value) {
                if (!this._peer || !this._peer.stream) /*what?*/return;
                switch(key) {
                    case 'hangup':
                        this._stop(false);
                        break;
                    case 'mute':
                    case 'unmute':
                    case 'video_off':
                    case 'video_on':
                        wrapRTC.mediaChannelAction(this._peer.stream, key);
                        this._sendAction(JSON.stringify({type:'metadata', key:key}), this._peer.key);
                        break;
                    }
                }
            },
        presentation: {
            presentations: [],
            _set_presentation: function(value) {
                var arr = null;
                if (value)
                    arr = value.match(/^([^:]+):([^:]+):([^:]+):(\d):(.+)$/);
                this.onPresentationChange(arr? {numPages:arr[1], presentationIndex:arr[2], presentationName:unescape(arr[3]), multipage:(arr[4]==1), url:arr[5]} : null);
                },
            _set_ptr: function(value) {
                var obj = null;
                if (value) {
                    if (!/^(\d+),(\d+)$/.exec(value))
                        return;
                    obj = {x:parseInt(RegExp.$1, 10),y:parseInt(RegExp.$2, 10)};
                    }
                this.onSetPointer(obj);
                },
            _onInit: function() {
                var n = this._api.notify, _this=this;
                this.onPresentationChange(null);
                n.subscribe(function(h){
                    if (h.attr===undefined && h.value===undefined) {
                        if (_this.presentations[h.idx] !== undefined) {
//                            if (sel_pr.val()==h.idx) /* if currently selected? */
//                                set_presentation('');
//                            sel_pr.find('option[value="' + h.idx + '"]').remove();
                            _this.onRemovePresentation(h.idx);
                            delete _this.presentations[h.idx];
                            }
                        }
                    else {
                        if (typeof(_this.presentations[h.idx])==="undefined")
                            _this.presentations[h.idx] = {media_file:{id:h.idx}};
                        _this.presentations[h.idx].media_file[h.attr] = h.value;
                        var mf = _this.presentations[h.idx].media_file;
                        if (mf.name && mf.url && mf.slideshow_pages>0 && !mf._added) {
                            mf._added = true;
                            _this.onAddPresentation(mf.id, mf.name);
                            }
                        }
                    },'media_files');
                n.subscribe(function(o){
                    switch(o.variable) {
                        case 'presenter':
                            if (o.value) {
                                var arr = o.value.match(/^\s*([^:]+):(.*)$/);
                                if (arr && arr.length==3) {
                                //$j('#presenter').text(' Presenter: ' + arr[2] + ' '); -- try the look below for a while ...
/*
                                $j('#presenter').html(' <em>Presenter:</em> ' + arr[2] + ' ');
                                if (arr[1] == BR._api.context.user_id) {    /* we are presenting *./
                                    $j('.not_presenting').css('display','none');
                                    $j('.presenting').css('display','inline');
                                    }
                                else {                              /* somebody else presenting *./
                                    $j('.presenting').css('display','none');
                                    $j('.not_presenting').css('display','inline');
                                    } */
                                    _this.onPresenterChange(arr[2], arr[1]==_this._api.context.user_id);
                                    }
                                }
                            break;

                        case 'presentation':
                            _this._set_presentation(o.value);
                            break;

                        case 'ptr':
                            _this._set_ptr(o.value);
                            return;     /* skip _startStopPointer() at end */

                        case 'show':
                            _this.onChangePage(o.value);
                            break;

                        case undefined:
                            if (o.value==undefined) {   /* reset */ // tmp TODO. working on this ...
/*
                            $j('#presenter').text('');
                            $j('.not_presenting').css('display','inline');
                            $j('.presenting').css('display','none');
*/
                                _this._set_presentation('');
                                _this.onPresenterChange('',false);
                                }
                            break;
                        }
                    _this.onCheckPointer();
                    },'slide');
                },
//            onUpdate(data) {},
            onChangePage: function(newPageNum) {},
            onPresentationChange: function(obj) {},
            onPresenterChange: function(name, me) {},
            onAddPresentation: function(idx, name) {},
            onRemovePresentation: function(idx) {},
            onSetPointer: function(obj) {},
            onCheckPointer: function() {},
            changePresentation: function(idx) {
                var mf = (idx in this.presentations) ? this.presentations[idx].media_file : null;
                this._api.commands.slideAction('presentation', mf ?
                    (mf.slideshow_pages + ':' + mf.id + ':' + escape(mf.name) + ':' + (mf.multipage?1:0) + ':' + mf.url) : undefined);
                },
            changePage: function(newPage) {
                this._api.commands.slideAction('show', newPage);
                },
            close: function() {
                this._api.commands.slideAction(undefined, undefined);
                },
            makeMePresenter: function() {
                this._api.commands.slideAction('presenter', this._api.context.user_id + ':' + this._api.context.user_name);
                },
            setPointer: function(x, y) {
                this._api.commands.slideAction('ptr', x + ',' + y);
                }
            }
        }
})();

