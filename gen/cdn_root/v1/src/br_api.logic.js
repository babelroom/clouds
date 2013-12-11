
(function() {
    var LogicContainer = function() {
        var br_room_context = null; /* bit (?) of a hack .. */
    /* 
    ** Note: the logic container wraps older code which is being refactored
    */

/* -- from old br_commands.js */
var BRCommands = {
    cid: '',
    last_ts: undefined,
    _stream: null,

    _memberKV: function(idx,value,attr) {
        /* fix formatting in here ... */
            switch(attr) {
                case undefined:
                    BRDashboard.fire({type:'listener',command:(value==undefined?'del':'add'),mid:idx});
                    break;
                case 'mute':
                case 'pa':
                case 'deaf':
                    var o = {};
                    /* if "true" value is an empty string ... (therefore would implicitly cast to boolean false) */
                    o[attr] = (typeof value === 'undefined') ? false : true ;
                    BRDashboard.fire({type:'listener',command:'attr',mid:idx,attrs:o});
                    break;
                case 'group':
                    if (value=='0')
                        value = '';
                    /* fall thru */
                case 'name':
                case 'callerid':
                case 'dialout':
                case 'role':
                case 'poll':
                case 'user_id':
                    var o = {};
                    o[attr] = value;
                    BRDashboard.fire({type:'listener',command:'attr',mid:idx,attrs:o});
                    break;
                default:
                }
    },
    _connectionKV: function(id,attr,value) {
        if (typeof(value)!=='undefined' || attr) {
            if (attr) {
                if (/^video-(\d+)-(.*)$/.exec(attr)) {
                    var uid = RegExp.$1
                        , rest = RegExp.$2;
                    BRDashboard.fire({type:'video',connection_id:id,user_id:uid,subkey:rest,data:value});
                    }
                }
            else {
                if (/^([^-]+)-([^-]+)-(\d+)$/.exec(value)) {
                    var el = RegExp.$1
                        , cs = RegExp.$2
                        , uid = RegExp.$3;
                    if (cs==br_room_context.connection_salt)  {
                        BRDashboard.connection_id = id;
                        //BRToolbar.door('loaded');// XXXXX disabled for refactoring
                        BRDashboard.updateRoomContext('is_live',true);
                        }
                    BRDashboard.fire({type:'online',command:'mod',connection_id:id,estream_label: el, connection_salt: cs, user_id: uid});
                    }
                }
            }
        else {
            BRDashboard.fire({type:'online',command:'del',connection_id:id});
            }
    },
    _dispatchKV: function(str, ts) {
        if (str.length < 1)
            return;
        var key;
        var value;
        if (str.match(/^([^:]*):\s*(.*)$/)) {
            key = RegExp.$1;
            value = RegExp.$2;
            }
        else {
            key = str;
            value = undefined;
            }
        var verb = id = idx = attr = undefined;
        if (key.match(/^([^-]*)-(.*)$/)) {
            verb = RegExp.$1;
            var tmp = RegExp.$2;
            if (tmp.match(/^([^-]*)-(.*)$/)) {
                id = RegExp.$1;
                attr = RegExp.$2;
                }
            else {
                id = tmp;
                }
            var idx = parseInt(id, 10);
            }
        else  {
            verb = key;
            }
        switch(verb) {
            case '_':
                BRCommands._connectionKV(id,attr,value);
                break;
            case 'chat':
                BRDashboard.fire({type:'chat',ts:ts,data:value});
                break;
            case 'member':
                BRCommands._memberKV(idx,value,attr);
                break;
            case 'talking':
                BRDashboard.fire({type:'talking',mid:idx,value:value});
                break;
            case 'lock':
                BRDashboard.fire({type:'lock',on_if_defined:value});
                break;
            case 'recording':
                BRDashboard.fire({type:'recording',on_if_defined:value});
                break;
            case 'slide':
                BRDashboard.fire({type:'slide',variable:id,value:value});
                break;
            case 'command':
                BRDashboard.fire({type:'command',command:id,value:value});
                break;
            case 'pin':
                BRDashboard.fire({type:'pin',pin:id,user_id:value});
                break;
            case 'gue':     /* global user event */
                BRDashboard.fire({type:'gue',id:id,idx:idx,attr:attr,value:value});
                break;

            /* binlog stuff */
            case 'media_files':
            case 'invitations':
            case 'users':
            case 'conferences':
                BRDashboard.fire({type:verb,id:id,idx:idx,attr:attr,value:value});
                break;
            };
    },

    _fire: function(data,ts) {
        var ctrl = data.substring(0,1);
        var str = data.substring(1);
        var arr;
        switch(ctrl) {
            case 'C':   /* (old?) chat message: leave this in the for present, depreciate soon TODO FIXME */
                BRDashboard.fire({type:'chat',ts:ts,data:str});
                break;
            case 'D':
// this was meant to catch an outbound call terminating so we could lose the 'dialing...' msg
// problem is doesn't work so well in the event of a conference to be started with this call ...
// so I guess ... later
//console.log('Dmsg='+str);
                break;
            case 'K':
                BRDashboard.fire({type:'_K',ts:ts,str:str});   // support for old application background grid
                BRCommands._dispatchKV(str, ts);
                //arr = str.match(/^member-([^:]+):\s?(\S+)$/); -- that was wrong ...
                arr = str.match(/^member-([^:-]+):\s?(\S+)$/);
                if (arr && arr.length>2) {
                    BRDashboard.fire({type:'dialer',state:'connected',token:arr[2]});
                    }
                break;
            case 'R':
                /* this next line is the only reason we don't forget this 'R' schema in favor of K values */
                BRDashboard.fire({type:'_R',ts:ts,str:str});   // support for old application background grid
/* actually convert them to K values now ...
                BRDashboard.fire({type:'lock',on_if_defined:undefined}); // conferences start unlocked ...
                BRDashboard.fire({type:'recording',on_if_defined:undefined}); // conferences start not recording ... */
                break;
            default:
            }
    },

    dispatchData2: function(data) {
        var ts = undefined;
        if (/^([a-f0-9]+)(.*)$/.exec(data)) {
            var tmp = RegExp.$1;
            if (tmp.length>4 ) { /* absolute timestamp */
                BRCommands.last_ts = ts = parseInt(tmp,16);
                }
            else if (BRCommands.last_ts!==undefined) {  /* relative timestamp */
                ts = BRCommands.last_ts + parseInt(tmp,16);
                }
            if (ts!==undefined)
                ts *= 100;
            data = RegExp.$2;
            }
        BRCommands.dispatchData3(data,ts);
    },

    dispatchData3: function(data,ts) {
        BRCommands._fire(data,ts);
    },

    updateProgress: function(str) {
        BRDashboard.fire({type:'log',data:str});
    },

    doPUT: function(queue, data, fn) {  /* old */
console.log('depreciated',queue,data,fn);
    },

    put: function(template, args, fn) {  /* new */
        BRCommands._stream && BRCommands._stream.put({cid: BRCommands.cid, template: template, args:args}, fn);
    },

    sendChat: function(user_id, user_name, msg, fn) {
        // -- now depreciated var msg = user_id + '-' + user_name + ': ' + msg.text/* add other fields shortly ... */;
        msg.user_id = user_id;
        msg.user = user_name;
        msg = JSON.stringify(msg);
        BRCommands.put('chat', msg, fn);
    },

    conferenceAction: function(action) {
        BRCommands.put('conferenceAction', action, function() { BRCommands.updateProgress("Done: "+action); });
    },

    conferenceIdsAction: function(ids,action) {
        /* allowed by non-admins temporarily (because users mute cmd could be in there...) */
        BRCommands.put('conferenceIdsAction', [ids, action], function() { BRCommands.updateProgress("Done: "+action+' '+ids); });
    },

    conferenceSelectedAction: function(action) {
        ids = BRDashboard.selectedListeners;
        BRCommands.conferenceIdsAction(ids,action);
    },

/*
// Currently unused
function fsAction(value)
{
    BRCommands.doPUT('/fs/_','F' + value, function() { BRCommands.updateProgress("Done: "+value); });
}
*/
    fsDialout: function(pin,full_number,caller_id_name,token) {
        var fs_number = full_number.replace(/^\+1/,'1').replace(/^\+/,'011');
        var cmd = pin + ':' + fs_number + ':' + token + ':' + caller_id_name;
        //BRCommands.doPUT('/fs/_','O' + cmd, function() { BRCommands.updateProgress("Originate done: "+cmd); });
        BRCommands.put('dialCmd', 'O' + cmd, function() { BRCommands.updateProgress("Originate done: "+cmd); });
        BRDashboard.fire({type:'dialer',state:'calling',full_number:full_number,pin:pin,token:token,timeout_seconds:30});
    },

    fsHup: function(token) {
        var cmd = token + '::::';
        //BRCommands.doPUT('/fs/_','H' + cmd, function() { BRCommands.updateProgress("hangup done: "+cmd); });
        BRCommands.put('dialCmd', 'H' + cmd, function() { BRCommands.updateProgress("hangup done: "+cmd); });
//console.log('hup ('+cmd+')');
        // bit of a hack but ... (we can't reliably get notified when an outbound call
        // is cancelled if that call would have started the conference...)
        BRDashboard.fire({type:'dialer',state:'cancelled',token:token});
    },

    videoAction: function(subkey, value) {
        var cmd = '-' + subkey;
        if (typeof(value)!=='undefined')
            cmd += ':' + value;
        BRCommands.put('video', {connection_id:BRDashboard.connection_id,uid:br_room_context.user_id,cmd:cmd}, function()
            { BRCommands.updateProgress("Done - videoAction: "+cmd); });
    },

    gue: function(attr,value) {
        var sattr = attr ? '-'+attr : ''
            , svalue = value ? ': '+value : ''
            ;
        var h = {idx:br_room_context.user_id, attr:sattr, value:svalue};
        BRCommands.put('gue', h, function() { BRCommands.updateProgress("Done - gue: "+h.toString()); });
    },

    slideAction: function(variable,value) {
        var cmd = '';
        if (variable)
            cmd += '-' + variable;
        if (value)
            cmd += ': ' + value;
        BRCommands.put('slide', cmd, function() { BRCommands.updateProgress("Done - slideAction: "+cmd); });
    },

    commandAction: function(command) {
        var cmd = '';
        if (command)
            cmd += '-' + command;
        cmd += ': ' + ((new Date).getTime());
        BRCommands.put('command', cmd, function() { BRCommands.updateProgress("Done - commandAction: "+cmd); });
    },

    clearAction: function(key,attr) {
        var cmd = key;
        if (attr)
            cmd += '-'+attr;
        BRCommands.put('clear', cmd, function() { BRCommands.updateProgress("Done - clearAction: "+cmd); });
    },

    _doMove: function(to_group,ids) {
        BRCommands.put('move', [to_group, ids], function() { BRCommands.updateProgress("Done: doMove "+ids); });
    },

    dissolveRooms: function(depreciate_id) {
        BRCommands._doMove(0,'all');
    },

    moveToRoom: function(depreciated_id,destRoomField) {
        ids = BRDashboard.selectedListeners.join(' ');
        BRCommands._doMove(destRoomField.value,ids);
    },

    breakOut: function(depreciate_id,groupField) {
        var groupCode = groupField.value;
        if (groupCode<0)
            return;
        function groups_of_x(size,index) {
                var ways = Math.min(9,Math.round(size / groupCode));
                if (ways==0)
                    ways=1;
                return (index % ways) + 1;
                }
        function x_groups(size,index) {
                var ways = Math.min(9,(groupCode-100));
                return (index % ways) + 1;
                }
        var fn = (groupCode<100) ? groups_of_x : x_groups;
        var len = BRDashboard.selectedListeners.length;
        var groups = {};
        for(var idx=0; idx<len; idx++) {
            var id = BRDashboard.selectedListeners[idx];
            var assignment = fn(len,idx);
            if (!groups[assignment])
                groups[assignment] = '';
            groups[assignment] += id + ' ';
            }
        len = groups.length;
        for(var idx in groups) {
            BRCommands._doMove(idx,groups[idx]);
            }
    },

    //start: function(estream_server,estream_cid) {
    //start: function(/*api_obj, */ estream_cid, fnerror) {
    start: function(api_obj, fnerror) {
        br_room_context = api_obj.context;
        BRCommands.cid = br_room_context.conference_estream_id;
        
        BRDashboard.load();
        BRCommands._stream = api_obj.stream();
        /* we could get rid of this .. (explicit attach) */
        BRCommands._stream.attach(BRCommands.cid, br_room_context.connection_salt, br_room_context.user_id, function(e,d){
            if (e) fnerror(e);
            else BRCommands.dispatchData2(d);
            });
    }
};
/* end of old code */



/* -- from old br_dashboard.js */
var BRDashboard = {
    user_map: {},
    invitees: {},
    invitee_id_by_user: {},
    listeners: [],
    listener_data: {},
    selectedListeners: [],
    online_2_user_map: {},
//    listener_2_user_map: {}, -- commenting out because it appears not to be used
    boxes: {},  /* boxes are user specific presence entities which consolidate online/listener/video etc. */
//    id: 1,
    connection_id: null,
    notification_thread_id: undefined,
    notification_dict: {},
    conference_access_config: {},       /* parsed json version */

    /* internal subscription subsystem */
    list_pre: {},
    list: {},
    list_post: {},
    _subscribe: function (fn, type, priority) {
        var l;
        if (priority<0) { l = this.list_post; }
        else if (priority>0) { l = this.list_pre; }
        else l = this.list;
        if (typeof l[type] === "undefined") {
            l[type] = [];
        }
        l[type].push(fn);
    },
    subscribe: function (fn, type) {
        this._subscribe(fn, type, 0);
    },
    _unsubscribe: function (ll,fn) {
        for(var key in ll) {
            var l = ll[key],
                i = l.indexOf(fn);
            if (i>-1)
                l.splice(i,1);
            }
    },
    unsubscribe: function (fn) {
        this._unsubscribe(this.list_pre, fn);
        this._unsubscribe(this.list, fn);
        this._unsubscribe(this.list_post, fn);
    },
    _fire: function (l,data) {
        if (!l)
            return;
        var max = l.length, i, copy = [];  /* we're doing it this way in case the function mutates the list via unsubscribe or subscribe et. al. */
        for (i=0; i<max; i++)
            copy[i] = l[i];
        for (i=0; i<max; i++)
            copy[i](data);
    },
    fire: function (data) {
        if (!data)
            return;
        this._fire(this.list_pre[data.type], data);
        this._fire(this.list[data.type], data);
        this._fire(this.list_post[data.type], data);
    },

    ass: function(assertion) {
        /* TODO later */
    },

    box: function(user_idx, key, attr, value) {
        var user_id = user_idx;
        switch(typeof user_idx) {
            case "undefined": return false;
            case "number":              /* lots of numbers as well */
                user_id = user_idx.toString();
                break;
            default:
                //BRUtils.log('box user is not a number', typeof user_idx, user_idx); -- fires all over the place
                user_idx = parseInt(user_idx, 10);    // is this a hack?
            }
        function presence_count(box) {
            BRDashboard.ass(box._listeners>=0);
            BRDashboard.ass(box._online>=0);
            return box._listeners + box._online;
/*
            return +    // don't omit the + to force undefined to 0
                ('connection_id' in box) +
                ('mid' in box) +
                0;
*/
            }
        var have_box = (user_idx in BRDashboard.boxes);
        var old_presence_count = 0;
        var new_presence_count = 0;
        var old_data = {};
        if (have_box) {
            var data = BRDashboard.boxes[user_idx];
            for (var data_key in data)
                if (data.hasOwnProperty(data_key))   
                    old_data[data_key] = data[data_key];
            old_presence_count = presence_count(old_data);
            }
        if (typeof(key) === 'undefined') {  /* del */
            if (have_box) {
                BRDashboard.fire({type:'box',command:'del',idx:user_idx,id:user_id,data:BRDashboard.boxes[user_idx],old_data:old_data});
                delete BRDashboard.boxes[user_idx];
                return ;
                }
            }
        else {                              /* new/add */
            if (!have_box)
                BRDashboard.boxes[user_idx] = {user_idx:user_idx, user_id: user_id, connection_ids:{}, mids:{}, _online:0, _listeners:0};
            var b = BRDashboard.boxes[user_idx];
            if (typeof value === 'undefined') {
                switch(key) {
                                            /* use 'in' ?? */
                                            /*    vvv      */
                    case 'connection_id': if (typeof(b.connection_ids[attr])!=="undefined") { delete b.connection_ids[attr]; b._online--; }; break;
                    case 'mid': if (typeof(b.mids[attr])!=="undefined") { delete b.mids[attr]; b._listeners--; }; break;
                    default:
                        delete BRDashboard.boxes[user_idx][key];
                    }
/* move in case so we can yank connection_id, mid, but note 1 usage still exists in br_toolbar */
//                delete BRDashboard.boxes[user_idx][key];
                }
            else {
                switch(key) {
                    case 'connection_id': if (typeof(b.connection_ids[attr])==="undefined") { b._online++; }; b.connection_ids[attr]=value; break;
                    case 'mid': if (typeof(b.mids[attr])==="undefined") { b._listeners++; }; b.mids[attr]=value; break;
                    default:
                        BRDashboard.boxes[user_idx][key] = value;
                    }
/* move in case so we can yank connection_id, mid, but note 1 usage still exists in br_toolbar */
//                BRDashboard.boxes[user_idx][key] = attr||value;   // todo move use into case
                }
            if (!have_box)
                BRDashboard.fire({type:'box',command:'add',idx:user_idx,id:user_id,data:BRDashboard.boxes[user_idx],old_data:old_data});
            }
        if (user_idx in BRDashboard.boxes) {
            new_presence_count = presence_count(BRDashboard.boxes[user_idx]);
            BRDashboard.boxes[user_idx].presence_count = new_presence_count;
            }
        var command = 'update';
        if (new_presence_count>0 && old_presence_count==0)
            command = 'show';
        else if (old_presence_count>0 && new_presence_count==0)
            command = 'hide';
//console.log(old_presence_count,new_presence_count,command,BRDashboard.boxes[user_idx],old_data);
        BRDashboard.fire({type:'box',command:command,idx:user_idx,id:user_id,data:BRDashboard.boxes[user_idx],old_data:old_data});
    },

    parseAndSetAccessConfig: function(ac) {
        BRDashboard.conference_access_config = BRDynamic.readOptions(ac, _br_v1_conference_options);
    },

    load: function() {
        /* pretty important that this loader runs and subscribes first, so the
           data it tracks is accurate for user notifications
        */
        BRDashboard._subscribe(function(o){
            if (o.attr!==undefined || o.value!==undefined) {
                if (BRDashboard.user_map[o.idx]===undefined) {
                    BRDashboard.user_map[o.idx] = {};
                    BRDashboard.box(o.idx,'user_idx',null,o.idx);
                    }
                BRDashboard.user_map[o.idx][o.attr] = o.value;
                }
            },'users',1);
        BRDashboard._subscribe(function(o){
            if (o.attr===undefined && o.value===undefined) {
                delete BRDashboard.user_map[o.idx];
                BRDashboard.box(o.idx, undefined, null, undefined);
                }
            },'users',-1);
        BRDashboard._subscribe(function(o) {
            var idx = BRDashboard.listeners.indexOf(o.mid);
            if (o.command=='add' && idx==-1) {
                BRDashboard.listeners.push(o.mid);
                BRDashboard.listener_data[o.mid] = {};
                }
            else if (o.command=='attr' && idx!=-1) {
                /* register listener dtmf to their user in box */
                if (BRDashboard.listener_data[o.mid].poll !== o.attrs.poll && BRDashboard.listener_data[o.mid].user_id /*why wouldn't it be */)
                    BRDashboard.box(BRDashboard.listener_data[o.mid].user_id,'dtmf',null,o.attrs.poll);

                jQuery.extend(BRDashboard.listener_data[o.mid], o.attrs);
                if ('user_id' in o.attrs)
                    BRDashboard.box(o.attrs['user_id']/*will convert*/,'mid',o.mid,true);
                }
            },'listener',1);
        BRDashboard._subscribe(function(o) {
            var idx = BRDashboard.listeners.indexOf(o.mid);
            if (o.command=='del' && idx!=-1) {
                if ('user_id' in BRDashboard.listener_data[o.mid])
                    BRDashboard.box(BRDashboard.listener_data[o.mid].user_id/*will convert*/,'mid',o.mid,undefined);
                BRDashboard.listeners.splice(idx,1);
                delete BRDashboard.listener_data[o.mid];
                }
            },'listener',-1);
        BRDashboard._subscribe(function(o) {
            if (o.command==='mod') {
                BRDashboard.online_2_user_map[o.connection_id] = o.user_id;
                BRDashboard.box(o.user_id/*will convert*/,'connection_id',o.connection_id,true);
                }
            },'online',1);
        BRDashboard._subscribe(function(o) {
            if (o.command==='del') {
                if (BRDashboard.online_2_user_map[o.connection_id]) {
                    BRDashboard.box(BRDashboard.online_2_user_map[o.connection_id],'connection_id',o.connection_id,undefined);
                    delete BRDashboard.online_2_user_map[o.connection_id];
                    }
                }
            },'online',-1);
        BRDashboard._subscribe(function(o) {
            if (o.command==='mod') {
                if (!BRDashboard.invitees[o.id])
                    BRDashboard.invitees[o.id] = o.data;
                else
                    jQuery.extend(BRDashboard.invitees[o.id], o.data);
                if (typeof o.user_id != 'undefined') {
                    BRDashboard.invitee_id_by_user[o.user_id] = o.id;
                    BRDashboard.box(o.user_id/*will convert*/,'invitee_id',null,o.id);
                    }
                }
            },'invitee',1);
        BRDashboard._subscribe(function(o) {
            if (o.command==='del') {
                delete BRDashboard.invitees[o.id];
                if (typeof o.user_id != 'undefined')
                    delete BRDashboard.invitee_id_by_user[o.user_id];
                }
            },'invitee',-1);
        BRDashboard._subscribe(function(o) {
            var idx = BRDashboard.selectedListeners.indexOf(o.id);
            if (o.selected && idx==-1)
                BRDashboard.selectedListeners.push(o.id);
            if (!o.selected && idx!=-1)
                BRDashboard.selectedListeners.splice(idx,1);
            },'select_listener',1);
        BRDashboard._subscribe(function(o) {
            var user_id = undefined;
            if (o.attr=="user_id")
                user_id = o.value
            var h = {};
            h[o.attr] = o.value;
            if (br_room_context.invitation_id===/*intentional*/o.idx && o.attr==="role") {
                BRDashboard.updateRoomContext('is_host', (o.value==="Host"));
                }
            BRDashboard.fire({type:'invitee',command:'mod',id:o.idx,user_id:user_id,data:h});
            },'invitations',1);
/*
XXX disabled for refactoring
        BRDashboard._subscribe(function(o) {
            switch(o.command) {
                case 'refresh':
                    if (br_room_context.is_live)
                        BRToolbar.pageReload();
                    break;
                default:;
                }
            },'command',1);
*/
        BRDashboard._subscribe(function(o) {
            if (o.id!=/*intentional*/br_room_context.conference_id) /* how could it be otherwise? */
                return;
            if (o.attr==="access_config")
                br_room_context.conference_access_config = o.value;
            }, 'conferences',1);
        BRDashboard._subscribe(function(o) {
            if (o.attr==="dtmf")
                BRDashboard.box(o.idx,'dtmf',null,o.value);
            },'gue',1);
        BRDashboard._subscribe(function(o) {
            if (o.updated && o.updated.conference_access_config)
                parseAndSetAccessConfig(br_room_context.conference_access_config);
            },'room_context',1);
    },

    updateRoomContext: function(key, value) {
        var h = {};
        h[key] = true;
        br_room_context[key] = value;
        BRDashboard.fire({type:'room_context',updated:h,'new':br_room_context});
    },

/*
    clearAllDTMF: function() {
        for(var i in BRDashboard.boxes) ---- NOOOOO!!!
            if (i/*paranoid*./ && BRDashboard.boxes.hasOwnProperty(i)) {
                var box = BRDashboard.boxes[i];
                if (!box.presence_count) return; /* maybe unnessary, re-consider if we see straggling dtmf/votes *./
                    BRCommands.gue(i, null);
                }
    },
*/

    notify: function(key, fn) {
        function interval() {
            var empty = true;
            for(var key in BRDashboard.notification_dict)
                if (BRDashboard.notification_dict.hasOwnProperty(key)) {
                    /*
                    6 on
                    5 off
                    4 on
                    3 off
                    2 on
                    1 off
                    0 on, no further checks
                    */
                    var i = BRDashboard.notification_dict[key].cdown;
                    if (i>=0) {
                        BRDashboard.notification_dict[key].fn((i%2) ? 2: 1);
                        BRDashboard.notification_dict[key].cdown--;
                        empty = false;
                        }
                    }
            if (empty) {
                clearInterval(BRDashboard.notification_thread_id);
                BRDashboard.notification_thread_id = undefined;
                }
            }
        if (typeof(BRDashboard.notification_dict[key])==="undefined")
            fn(0);
        BRDashboard.notification_dict[key] = {cdown: 6, fn: fn};
        if (typeof(BRDashboard.notification_thread_id)==="undefined") {
            interval();
            BRDashboard.notification_thread_id = setInterval(interval, 1000);
            }
    },

    resetNotify: function(key) {
        var dict = BRDashboard.notification_dict[key];
        if (typeof(dict)!=="undefined") {
            BRDashboard.notification_dict[key].fn(3);
            delete BRDashboard.notification_dict[key];
            }
    }
};
/* end of old code */

        this.commands = BRCommands;
        this.notify = BRDashboard;
        }

    typeof window.BR==="undefined"?window.BR={v1:{}}:typeof window.BR.v1==="undefined"&&(window.BR.v1={});
    window.BR.v1.logic = {create: function() { return new LogicContainer(); }};
})();

