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
            _state: null,
            _indicators: null,
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
            _answer: function(peer_key, msg, obj) {
                var _this = this;
                if (_this.options.stereo)
                    wrapRTC.addStereoToSDP(msg);
                _this.onCallStatusUpdate('ringing', {awaiting_permission:true, name:_this._uname(obj.user_id)});
                wrapRTC.openWebcam({
//(function foo(obj) {return obj.setStream(null);})({
                    element: _this.localVideo,
                    onSupportFailure: function(msg) { console.log(1,msg); /*TODO*/ },
                    onError: function(code) {
                        switch(code) {
                            case 1: /* camera / microphone access denied */
                                _this.onCallStatusUpdate('permission_denied');
                                _this.onCallStatusUpdate('done');
                                break;
                            default:
                            }
                        },
                    setStream: function(stream) {
                        _this.onCallStatusUpdate('ringing', {awaiting_permission:false, name:_this._uname(obj.user_id)});
                        wrapRTC.answer(msg, stream, {
                            //element: _this.localVideo,
                            element: _this.remoteVideo,
                            onError: function(error) { console.log("error from wrapRTC.answer()", error); },
                            setPC: function(pc) { _this._setPC(pc);},
                            signalOut: function(msg) { _this._sendAction(JSON.stringify(msg), peer_key); },
                            //signalOut: function(msg) { console.log(['aso',msg]);if (!msg||msg.type!=='candidate')_this._sendAction(JSON.stringify(msg), peer_key); },
//                            setStream: function(stream) { console.log(['answer','setStream']); },
                            connected: function() { _this.onCallStatusUpdate('connected'); },
                            disconnected: function() { _this.onCallStatusUpdate('done'); }
                            });
                        }
                    });
                },
            _signalIn: function(msg) {
                var _this = this;
console.log(msg);
                switch(msg.type) {
/*
 -- moved
                    case 'offer':
//console.log(this.localVideo);
                        _this._answer(peer_key, msg);
                        break;
*/
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
                    }
                },
            _setupVideo: function() {
                var n = this._api.notify, _this=this;
                this._key = Math.random().toString(36).substring(2);
                n.subscribe(function(o){
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
                                if (obj.type==='offer')
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
                        _this.onUserStatusUpdate(o.user_id, from_key, 'available');
                        }
                    },'video');
                n.subscribe(function(o) {
                    /* user has gone offline, delete any associated video */
                    if (o.command==='del' && o.connection_id!=/*obviously this can't happen but include for completeness*/n.connection_id) {
                        //peer_webcam_onoff(o.connection_id); -- peer has gone away 
                        }
                    },'online');
                n.subscribe(function(o){
                    if(o.updated.is_live && _this._api.context.is_live) {
                        _this._sendAction('Supported'); /* advertise our availability */
                        }
                    },'room_context');
                },
            _onInit: function() {
                if (this._haveWebRTC) {
                    this._setupVideo();
                    }
                },
            localVideo: null,
            remoteVideo: null,
            onUserStatusUpdate: function(uid, key, state) {},
            onCallStatusUpdate: function(state, flags) {},
            // TODO: deal with errors ... (2)
            call: function(uid,peer_key) {
                var _this = this;
                _this.onCallStatusUpdate('calling', {awaiting_permission:true, name:_this._uname(uid)});
                wrapRTC.openWebcam({
                    element: _this.localVideo,
                    onSupportFailure: function(msg) { console.log(1,msg); /*TODO*/ },
                    onError: function(code) {
                        switch(code) {
                            case 1: /* camera / microphone access denied */
                                _this.onCallStatusUpdate('permission_denied');
                                _this.onCallStatusUpdate('done');
                                break;
                            default:
                            }
                        },
                    setStream: function(stream) {
                        _this.onCallStatusUpdate('calling', {awaiting_permission:false, name:_this._uname(uid)});
                        wrapRTC.callPeer(stream, {
                            element: _this.remoteVideo,
                            onError: function(error) { console.log("error from wrapRTC.callPeer()", error); },
                            setPC: function(pc) { _this._setPC(pc);},
                            connected: function() { _this.onCallStatusUpdate('connected'); },
                            disconnected: function() { _this.onCallStatusUpdate('done'); },
                            signalOut: function(msg) { _this._sendAction(JSON.stringify(msg), peer_key); }
                            });
                        }
                    });
                },
            control: function(key, value) {
                switch(key) {
                    case 'hangup':
                        this.onCallStatusUpdate('done');
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

