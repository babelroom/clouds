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
/*
                    if (value==undefined) {
                        var selected_ids = grid.jqGrid('getGridParam','selarrrow');
                        if (selected_ids.indexOf(idx)>-1) {
                            Application.selectedParticipantCount--;
                            notifySelectedUpdated();
                            }
                        grid.jqGrid('delRowData',idx);
                        Application.totalParticipantCount--;
                        }
                    else {
                        grid.jqGrid('addRowData',idx,{icon: '<img src="'+BR.room.co..... OLD ... ntext.cdn_host+'/cdn/v1/c/img/blank.png" />'});
                        Application.totalParticipantCount++;
                        }
*/
//                    grid.jqGrid('setCell', idx, 'name', value, 'cs-participant-active',{});
//                    BRDashboard.fire({type:'listener',command:'name',mid:idx,name:value});
//                    break;
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
/*
                case 'poll':
                    grid.jqGrid('setRowData',idx,{poll: value});
                    Application.notifyListeners('poll',{index:idx, value:value});
                    break;
*/
                default:
                }
    },
    _connectionKV: function(id,value) {
        if (/^([^-]+)-([^-]+)-(\d+)$/.exec(value)) {
            var el = RegExp.$1
                , cs = RegExp.$2
                , uid = RegExp.$3;
            if (cs==BR.room.context.connection_salt)  {
                BRDashboard.connection_id = id;
                BRToolbar.door('loaded');
                BRDashboard.updateRoomContext('is_live',true);
//console.log((new Date()).getTime()/1000.0);
                }
            BRDashboard.fire({type:'online',command:'mod',connection_id:id,estream_label: el, connection_salt: cs, user_id: uid});
            }
        else {
            BRDashboard.fire({type:'online',command:'del',connection_id:id});
            }
    },
    _dispatchKV: function(str) {
        if (str.length < 1)
            return;
//console.log(str);
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

        var sk = key.split(/-/, 3); // subkeys
        //if (sk.length<2) -- changed down to 1 for 'lock' no mid -- conference general
        if (sk.length<1)
            return;
        var verb = sk[0];
        var id = sk[1];
        var idx = parseInt(id, 10);
        var attr = sk[2];
        switch(verb) {
            case '_':
                BRCommands._connectionKV(id,value);
                break;
            case 'member':
                BRCommands._memberKV(idx,value,attr);
                break;
            case 'talking':
                BRDashboard.fire({type:'talking',mid:idx,value:value});
                break;
            case 'video':
                BRDashboard.fire({type:'video',user_id:id,stream_id:attr,data:value});
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
//console.log(ctrl,str);
        switch(ctrl) {
            case 'C':   /* (old?) chat message */
                BRDashboard.fire({type:'chat',ts:ts,data:str});
                break;
            case 'D':
// this was meant to be to catch an outbound call terminating so we could lose the 'dialing...' msg
// problem is doesn't work so well in the event of a conference to be started with this call ...
// so I guess ... later
//console.log('Dmsg='+str);
                break;
            case 'K':
                BRDashboard.fire({type:'_K',ts:ts,str:str});   // support for old application background grid
                BRCommands._dispatchKV(str);
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
/*  TODO removing      Application.dispatch(data); */
        BRCommands._fire(data,ts);
    },

    updateProgress: function(str) {
        BRDashboard.fire({type:'log',data:str});
    },

    doPUT: function(queue, data, fn) {  /* old */
console.log('depreciated',queue,data,fn);
//        BRCommands._stream.old_put(queue, data, fn);
    },

    put: function(template, args, fn) {  /* new */
        BRCommands._stream.put({cid: BRCommands.cid, template: template, args:args}, fn);
    },

    sendChat: function(user_id, user_name, id) {
        var elem = document.getElementById(id);
        if (elem==undefined)
            return;
        var msg = user_id + '-' + user_name + ': ' + elem.value;
        BRCommands.put('chat', msg, function() { elem.value = ''; });
    },

/*
    muteAction: function(action) {
        BRCommands.doPUT('/fs/' + BRCommands.cid,'F' + 'bgapi conference ' + BRCommands.cid + ' ' + action, function() { ; });
    },
*/

    conferenceAction: function(action) {
//        BRCommands.doPUT('/fs/' + BRCommands.cid,'F' + 'bgapi conference ' + BRCommands.cid + ' ' + action, function() { BRCommands.updateProgress("Done: "+action); });
        BRCommands.put('conferenceAction', action, function() { BRCommands.updateProgress("Done: "+action); });
    },

    conferenceIdsAction: function(ids,action) {
        // leave this using old for the present as mute goes thru here ...
//        BRCommands.doPUT('/fs/' + BRCommands.cid,'M' + ids + ' ' + 'bgapi conference ' + BRCommands.cid + ' ' + action, function() { BRCommands.updateProgress("Done: "+action+' '+ids); });
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

    depreciated_dissolveRooms: function(depreciate_id) {
//        var jqg = jQuery("#" + id + "_grid");
//        var ids = jqg.jqGrid('getDataIDs').toString();
        var ids = BRDashboard.selectedListeners;
        BRCommands.doPUT('/fs/' + BRCommands.cid,'D' + BRCommands.cid + ' ' + ids, function() { BRCommands.updateProgress("Done: dissolveRooms: "+ids); });
    },

    _depreciated_doMove: function(depreciate_id,fnWhichRoom) {
        //var jqg = jQuery("#" + id + "_grid");
        //var allRows = jqg.jqGrid('getDataIDs');
        var allRows = BRDashboard.listeners;
        var totalData = BRCommands.cid + ' ';
        var len = allRows.length;
        for(var idx=0; idx<len; idx++) {
            var id = allRows[idx];
//var jqg = jQuery("#" + id + "_grid");
//var group = jqg.jqGrid('getCell',id,'group');
            var group = BRDashboard.listener_data[id].group;
//console.log('group='+group);
            totalData += id + ',' + (((group==undefined)||(group==''))?0:group) + ' ';
            }
        //var selRows = jqg.jqGrid('getGridParam','selarrrow');
        var selRows = BRDashboard.selectedListeners;
        if (selRows.length==0)
            return;
        totalData += ':';
        len = selRows.length;
        for(var idx=0; idx<len; idx++) {
            var id = selRows[idx];
            totalData += id+','+fnWhichRoom(len,idx)+' ';
            }
        BRCommands.doPUT('/fs/' + BRCommands.cid,'R' + totalData, function() { BRCommands.updateProgress("Done: moveToRoom" + totalData); });
    },

    depreciated_moveToRoom: function(depreciate_id,destRoomField) {
        var destRoom = destRoomField.value;
        if (destRoom<0)
            return;
        return BRCommands._doMove(depreciate_id, function(size,index) { return destRoom; });
    },

    videoAction: function(stream_id, start) {
        var cmd = '-' + BR.room.context.user_id + '-' + stream_id;
        if (start)
            cmd += ':';
//        BRCommands.doPUT('/conference/' + BRCommands.cid, cmd, function() { BRCommands.updateProgress("Done - videoAction: "+cmd); });
        BRCommands.put('video', cmd, function() { BRCommands.updateProgress("Done - videoAction: "+cmd); });
    },

    gue: function(attr,value) {
        var sattr = attr ? '-'+attr : ''
            , svalue = value ? ': '+value : ''
            ;
        var h = {idx:BR.room.context.user_id, attr:sattr, value:svalue};
        BRCommands.put('gue', h, function() { BRCommands.updateProgress("Done - gue: "+h.toString()); });
    },

    slideAction: function(variable,value) {
        var cmd = '';
        if (variable)
            cmd += '-' + variable;
        if (value)
            cmd += ': ' + value;
//        BRCommands.doPUT('/conference/' + BRCommands.cid, cmd, function() { BRCommands.updateProgress("Done - slideAction: "+cmd); });
        BRCommands.put('slide', cmd, function() { BRCommands.updateProgress("Done - slideAction: "+cmd); });
    },

    commandAction: function(command) {
        var cmd = '';
        if (command)
            cmd += '-' + command;
        cmd += ': ' + ((new Date).getTime());
//        BRCommands.doPUT('/conference/' + BRCommands.cid, cmd, function() { BRCommands.updateProgress("Done - commandAction: "+cmd); });
        BRCommands.put('command', cmd, function() { BRCommands.updateProgress("Done - commandAction: "+cmd); });
    },

    clearAction: function(key,attr) {
        var cmd = key;
        if (attr)
            cmd += '-'+attr;
        BRCommands.put('clear', cmd, function() { BRCommands.updateProgress("Done - clearAction: "+cmd); });
    },

    _doMove: function(to_group,ids) {
//        BRCommands.doPUT('/fs/' + BRCommands.cid,'Fbgapi conference ' + BRCommands.cid + ' group ' + to_group + ' ' + ids, function() { BRCommands.updateProgress("Done: doMove "+ids); });
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
    start: function(/*api_obj, */ estream_cid, fnerror) {
        BRCommands.cid = estream_cid;
        
        BRDashboard.load();
        BRCommands._stream = BR.api.v1.stream();
        /* we could get rid of this .. (explicit attach) */
        BRCommands._stream.attach(BRCommands.cid, BR.room.context.connection_salt, BR.room.context.user_id, function(e,d){
            if (e) fnerror(e);
            else BRCommands.dispatchData2(d);
            });
    }
};

