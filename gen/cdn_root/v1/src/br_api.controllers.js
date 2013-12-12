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
                var n = this._api.notify, _this=this;
                n.subscribe(function(o){
                    if (_this.excludeSelf && o.id==_this._api.context.user_id)
                        return;
                    switch(o.command) {
                        case 'show':
                            _this.count++;
                            _this.onCountChange(_this.count);
                            _this.onAdd(o.idx, n.user_map[o.id]);
                            break;
                        case 'hide':
                            _this.count--;
                            _this.onRemove(o.idx, n.user_map[o.id]);
                            _this.onCountChange(_this.count);
                            break;
                        }
                    },'box');
                this.onCountChange(0);
                },
            onCountChange: function(newCount) {},
            onAdd: function(id,user) {},
            onRemove: function(id,user) {}
            },
        privateConference: {
            _haveWebRTC: typeof(wrapRTC)==="undefined" ? false : !!wrapRTC.supported,        /* whether or not webRTC/wraprtc is included and supported */
            _subscribe: function() {
                var n = this._api.notify, _this=this;
                n.subscribe(function(o){
                    var sk = o.subkey.split(/-/, 3); // subkeys
                    if (sk.length<1)    /* this is an error */
                        return;
                    var mechanism = sk[0];
                    var from_key = sk[1];
                    var to_key = sk[2];
                    if (to_key) { /* targeted for a specific peer */
/*                        if (
                                webrtc_data     &&
                                to_key === webrtc_data.key)                             /* webcam for this box (user_id matches) *./
                            webrtc_signal_in(o.connection_id, from_key, o.data); */
                        return;
                        }
                    if (o.connection_id != n.connection_id) {                           /* not our own connection */
                        //peer_webcam_onoff(o.connection_id, o.user_id, from_key, o.data);
                        if (!from_key) _this.onAvailable(o.user_id);
                        }
                    },'video');
                n.subscribe(function(o){
                    if(o.updated.is_live && _this._api.context.is_live){ _this._onLoad(_this._api.context); }
                    },'room_context');
                },
            _onInit: function() {
                this._subscribe();
                },
            _onLoad: function() {
                if (this._haveWebRTC)
                    this._api.commands.videoAction('webrtc' /* + '-' + webrtc_data.key*/, 'Supported'/*JSON.stringify(indicators.md)*/);
                },
            onAvailable: function(uid) {},
            onLoad: function() {},
            call: function(uid) {
console.log(['call',uid]);
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

