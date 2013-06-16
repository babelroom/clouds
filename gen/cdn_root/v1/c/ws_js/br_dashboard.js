var BRDashboard = {
    user_map: {},
    invitees: {},
    invitee_id_by_user: {},
/* THERE IS currently a problem that delete events on these lists delete the data before regular (i.e. non-priority) handlers can use them ... */
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
            BRUtils.ass(box._listeners>=0);
            BRUtils.ass(box._online>=0);
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
            if (BR.room.context.invitation_id===/*intentional*/o.idx && o.attr==="role") {
                BRDashboard.updateRoomContext('is_host', (o.value==="Host"));
                }
            BRDashboard.fire({type:'invitee',command:'mod',id:o.idx,user_id:user_id,data:h});
            },'invitations',1);
        BRDashboard._subscribe(function(o) {
            switch(o.command) {
                case 'refresh':
                    if (BR.room.context.is_live)
                        BRToolbar.pageReload();
                    break;
                default:;
                }
            },'command',1);
        BRDashboard._subscribe(function(o) {
            if (o.id!=/*intentional*/BR.room.context.conference_id) /* how could it be otherwise? */
                return;
            if (o.attr==="access_config")
                BR.room.context.conference_access_config = o.value;
            }, 'conferences',1);
        BRDashboard._subscribe(function(o) {
            if (o.attr==="dtmf")
                BRDashboard.box(o.idx,'dtmf',null,o.value);
            },'gue',1);
        BRDashboard._subscribe(function(o) {
            if (o.updated && o.updated.conference_access_config)
                parseAndSetAccessConfig(BR.room.context.conference_access_config);
            },'room_context',1);
    },

    updateRoomContext: function(key, value) {
        var h = {};
        h[key] = true;
        BR.room.context[key] = value;
        BRDashboard.fire({type:'room_context',updated:h,'new':BR.room.context});
    },

    foo_depreciate_and_remove_this: function() {
        var myid = this.id++;
        jQuery("body").append('<div id="iid_'+myid+'_dialog" style="display: none;">'+Application.content('guests',myid)+'</div>');
        jQuery('#iid_'+myid+'_dialog').dialog();
        jQuery("#" + myid + "_tabs").tabs();
        jQuery("#" + myid + "_finder_tabs").tabs();
        BRInvitees.dashboard_add_guests({
            root: '#'+myid+'_root',
            id: myid,
            guests: '#'+myid+'_guests',
            call: '#'+myid+'_call'
            });
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

