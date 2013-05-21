var BRWidgets = {
    id: 1,

    _crop: function(name,len) {
        var pres_max = (len?len:30);
        if (name.length<=pres_max)
            return name;
        return name.substring(0,pres_max-3) + '...';
    },

    _modified: function(h3tag) {
        if (!BR.room.context.is_live)
            return;
        if (h3tag.hasClass('ui-state-active') && !h3tag.hasClass('ui-state-highlight'))
            return;
        var key = h3tag.data('key');
        function notify_fn(flag) {
            var icon = h3tag.find('.icon-star');
            switch(flag) {
                case 0:
                    h3tag.addClass('ui-state-highlight');
                    setTimeout(function(){h3tag.removeClass('ui-state-highlight');}, 100);
                    // fall thru
                case 1:
                    icon.show();
                    break;
                case 2:
                    // fall thru
                case 3:
                    icon.hide();
                }
            }
        BRDashboard.notify(key, notify_fn);
    },

    _upload: function() {
        var $j = jQuery;
        function upload() {
            return false;
            }
        BROverlays.generic({
            content: function(id) {
                //var url = '/ws_js/fileuploader/index.html?url='
                var url = '/v1/c/ws_js/fileuploader/index.html?url='
                    + escape(BR.api.v1.get_host('myapi')+'/plugin/0/upload.js')
                    + '&ts=' + new Date().getTime()
                    + '&conference_id=' + BR.room.context.conference_id
                    + '&user_id=' + BR.room.context.user_id;
                return '<iframe src="'+url+'" width="780" height="360" frameborder="0"></iframe>';
                },
            logic:      function(id,selector) { 
                },
            title:  'Upload Files'
            });
    },

    nextId: function() {
        return 'widget_' + (BRWidgets.id++);
    },

    full_name: function(user_id) {
        var name = undefined;
        var h = BRDashboard.user_map[user_id];
        if (h) {
            if (h.name && h.last_name)
                name = h.name + ' ' + h.last_name;
            else if (h.name)
                name = h.name;
            else if (h.last_name)
                name = h.last_name;
            }
        if (!name)
            name = user_id;
        return name;
    },

    user_name: function(connection_ids,user_id) {
/*
        var name = undefined;
        var h = BRDashboard.user_map[user_id];
        if (h) {
            if (h.name && h.last_name)
                name = h.name + ' ' + h.last_name;
            else if (h.name)
                name = h.name;
            else if (h.last_name)
                name = h.last_name;
            }
        if (!name)
            name = user_id;
*/
        var name = BRWidgets.full_name(user_id) || ' ';
//console.log(name);
        //if (typeof((connection_ids||{})[BRDashboard.connection])!=="undefined")
//console.log(BRDashboard.connection_id, connection_ids, BRDashboard.connection_id in (connection_ids||{}));
        if (BRDashboard.connection_id in (connection_ids||{}))
            name = '<strong>'+name+'</strong> (you)';
//name+=' ['+user_id+']';
        return name;
    },

    _commonToolbar: function(id) {
        //return '<span id="'+id+'" style="padding: 2px; position: absolute; left: 340px; top: -30px;" class="ui-widget-header ui-corner-all"></span>';
        //return '<span style="position: absolute; top: -30px; left: 0; width: 100%;"><span id="'+id+'" style="padding: 2px; tp: -30px;" class="ui-widget-header ui-corner-all"></span></span>';
        //return '<span id="'+id+'" style="padding: 2px; position: relative; top: -30px; height:30px;" class="ui-widget-header ui-corner-all br-z-index-toolbar"></span>';
        //return '<span id="'+id+'" style="padding: 2px; position: relative; tp: -29px;" class="ui-widget-header ui-corner-all br-z-index-toolbar"></span>';
        return '<div id="'+id+'" style="padding: 1px 3px 1px 3px; psition: relative; height: 27px; width: default; display: inline-block; overflow: hidden;" class="ui-widget-header ui-corner-all br-z-index-toolbar"></div>';   /* z-index is not having any effect here ... 'inline-block' ?? */
    },

    styleSelect: function(sel) {
        sel.addClass("ui-button ui-corner-all br-select");
    },

    enableSelect: function(sel,enable) {
        if (enable) {
            sel.removeClass('ui-state-disabled');
            sel.prop('disabled', false);
            }
        else {
            sel.prop('disabled','true');
            sel.addClass('ui-state-disabled');
            }
    },

    rightMenu: function(sel) {
        var $j = jQuery;

        $j(sel).append('<div id="right_accordion" style="width: 205px;"></div>');
        var acc = '#right_accordion';

        var newId;
        var rootSelector;
        var accStr;

        function PanelTitleHTML(title, klass) {
            var cls = '';
            if ((typeof(klass)!=="undefined"))
                cls = ' class="'+klass+'"';
            var icon = {
                Dialpad: 'icon-phone',
                Participants: 'icon-user',
                Files: 'icon-folder-open',
                Controls: 'icon-dashboard',
                'Breakout Groups': 'icon-group',
                Polling: 'icon-bar-chart',
                'Advanced Audio Controls': 'icon2-equalizer',
                'Call Monitor': 'icon-signal'
                }[title];
            icon = ((typeof(icon)==="undefined")?'':'<i class="'+icon+' pull-right br-icon-rp-width"></i>');
            return '<h3' + cls + '><a href="#"><i class="icon-star"></i> ' + title + icon + '</a></h3>';
            }

        newId = BRWidgets.nextId();
        rootSelector = newId+'_root';
        accStr = PanelTitleHTML('Dialpad')+BRContent.content_dialpad(newId,rootSelector);
        $j(acc).append(accStr);
        BRWidgets.dialpad(newId,'#'+rootSelector);

        newId = BRWidgets.nextId();
        rootSelector = newId+'_root';
        accStr = PanelTitleHTML('Participants')+BRWidgets.content_participantSummary(newId, rootSelector);
        $j(acc).append(accStr);

        // TODO -- refactor the logic starting here in a seperate method
        var grid = $j('#right_listeners_table').jqGrid({
            datatype: "local",
            colModel:[
                {name:'id', index:'id', width:60, hidden: true, sorttype:"int"},
                {name:'name', label:'Listening', index:'text'},
                {name:'user_id', hidden: true}
                ],
            multiselect: true, // TODO tmp?
            width: 175,
            onSelectRow: function(rowid,selected) {
                            BRDashboard.fire({type:'select_listener',id:rowid,selected:selected});
                            },
            onSelectAll: function(rowids,selected) {
                            var len = rowids.length;    // this is actually an object => can't use "in"
                            for(var i=0; i<len; i++)
                                BRDashboard.fire({type:'select_listener',id:rowids[i],selected:selected});
                            }
            });
        BRDashboard.subscribe(function(o){
            // TODO this won't scale to large numbers ...
            var selected = (grid.jqGrid('getGridParam','selarrrow').indexOf(o.id)>-1);
//console.log(o.selected);
            if (selected != o.selected)
                grid.jqGrid('setSelection',o.id,false);
            },'select_listener');
        BRDashboard.subscribe(function(o){
            switch(o.command) {
                case 'add':
                    grid.jqGrid('addRowData',o.mid,{name:'--'});
                    break;
                case 'del':
                    if (grid.jqGrid('getGridParam','selarrrow').indexOf(o.id)>-1) {
                        BRDashboard.fire({type:'select_listener',id:o.id,selected:false});
                        }
                    grid.jqGrid('delRowData',o.mid);
                    break;
                case 'attr':
/*
                        grid.jqGrid('setRowData',o.mid,o.attrs);    /* set user_id *./
*/
                    if (typeof o.attrs.user_id != 'undefined') {
                        grid.jqGrid('setRowData',o.mid,o.attrs);    /* set user_id */
                        grid.jqGrid('setRowData',o.mid,{name:BRWidgets.user_name(null,o.attrs.user_id)});
                        }
                    break;
                }
/*
            var caption = '';
            switch(BRDashboard.listeners.length) {
                case 0: caption = 'No listeners'; break;
                case 1: caption = '1 listener'; break;
                default: caption = BRDashboard.listeners.length + ' listeners'; 
                }
            grid.setColProp('name',{label:caption}); // this doesn't appear to work either ...
            grid.setCaption(caption);
*/
            },'listener');


        BRWidgets.participantSummary(newId,'#'+rootSelector);

        newId = BRWidgets.nextId();
        rootSelector = newId+'_root';
        accStr = PanelTitleHTML('Files')+BRWidgets.content_files(newId,rootSelector);
        $j(acc).append(accStr);
        BRWidgets.files(newId,'#'+rootSelector);

        newId = BRWidgets.nextId();
        rootSelector = newId+'_root';
        accStr = PanelTitleHTML('Controls','host-only')+BRContent.content_controls(newId,rootSelector);
        $j(acc).append(accStr);
        BRWidgets.controls(newId,'#'+rootSelector);

        newId = BRWidgets.nextId();
        rootSelector = newId+'_root';
        accStr = PanelTitleHTML('Breakout Groups','host-only')+BRContent.content_breakoutGroups(newId,rootSelector);
        $j(acc).append(accStr);
        BRWidgets.breakoutGroups(newId,'#'+rootSelector);

        newId = BRWidgets.nextId();
        rootSelector = newId+'_root';
        accStr = PanelTitleHTML('Polling','host-only')+BRContent.content_polling(newId,rootSelector);
        $j(acc).append(accStr);
        BRWidgets.polling(newId,'#'+rootSelector);

        newId = BRWidgets.nextId();
        rootSelector = newId+'_root';
        accStr = PanelTitleHTML('Advanced Audio Controls', 'host-only')+BRContent.content_systemControls(newId,rootSelector);
        $j(acc).append(accStr);
        BRWidgets.systemControls(newId,'#'+rootSelector);

/*
        accStr = PanelTitleHTML('Call Monitor','host-only')+'<div id="call_monitor"></div>';
        $j(acc).append(accStr);
        BRWidgets.dialerMonitor(YYY'#call_monitor');
*/


/*
        $j(sel).resizable({
            minHeight: 140,
            resize: function() {
                $j('#right_listeners_table').accordion('resize');
                }
            }).append('<span class="ui-icon ui-icon-grip-dotted-horizontal" style="margin:2px auto;"></span>').css('display','block');
*/
//        $j(sel).find('.ui-jqgrid-sortable').css('display','none');
        //$j(acc).accordion({autoHeight: false}).css('display','block');
        $j(acc).accordion({
            autoHeight: true,
            /* reset any notification on new heading we've just clicked */
            activate: function(e, ui) {
                var key = ui.newHeader.data('key');
                key = $j(ui.newHeader).data('key');
                if (!key) return;
                BRDashboard.resetNotify(key);
                },
            animate: false  /* don't, it appears jerky */
            })
            .css('display','block')
            .find('.icon-star').hide();

        newId = BRWidgets.nextId();
        BRWidgets.chat(newId);
/*
-- so looks like this is not in use
        BRDashboard.subscribe(function(o){
            var rows = $j('#right_online_table').jqGrid('getRowData');
            for(var i=0; i<rows.length; i++) {
// methinks this is still in devel ...
                }
            },'invitee');
*/
/*
        function callers_change() {
            if (BRDashboard.listeners.length)
                $j('button.need1caller').button("enable");
            else
                $j('button.need1caller').button("disable");
            modified();
            }
        BRDashboard.subscribe(callers_change,'listener');
        callers_change();
*/
    },

    centerArea: function(sel) {
        var $j = jQuery;
        $j(sel).append('<div id="center_slides" style="display: none;"></div>');
        $j(sel).append('<div id="center_people" style="display: none;"></div>');
//        $j(sel).append('<div id="center_list" style="display: none;"></div>');
        BRWidgets.peopleArea('#center_people');
        BRWidgets.slidesArea('#center_slides');
//        BRWidgets.listArea('#center_list');
    },
    
    peopleArea: function(selector) {
        var $j = jQuery;
        var sel = $j(selector);
        sel.append('<center>'+BRWidgets._commonToolbar('people_toolbar')+'<div style="height: 2px;"></div><div id="boxes_container" class="tile_view br-z-index-boxes-container" style="display: none;"></div><div id="list_container" class="list_view" style="display: none;"><table id="_need_an_id_here"></table></div></center>');
        $j('#people_toolbar').append('\
<span>\
    <div class="list_view"></div>\
    <span id="people_view">\
        <input type="radio" id="tile" name="view" title="Tile" /><label for="tile"><i class="icon icon-th"></i></label>\
        <input type="radio" id="list" name="view" title="List" /><label for="list"><i class="icon icon-list"></i></label>\
    </span>\
    <!--<button class="tile_view" title="Sort"><i class="icon icon-sort"></i>&nbsp;Sort</button>-->\
    <button id="tile_organize" class="tile_view" title="Organize"><i class="icon icon-th-large"></i>&nbsp;Organize</button>\
    <span class="list_view"><input id="listeners_only" type="checkbox" disabled checked /><label for="listeners_only" style="color: gray; font-weight: normal;">Listeners Only</label></span>\
</span>\
');
        /* list */
        BRParticipants.openParticipantWindow2(sel.find('div#list_container > table'));
        sel.find('div .ui-jqgrid-bdiv').css('overflow-x','hidden');

        /* boxes */
        var have_webrtc = typeof(wrapRTC)==="undefined" ? false :  wrapRTC.supported;    /* whether or not webrtc is included and supported */



        var have_flash = false;
        /* ref: http://stackoverflow.com/questions/8576999/how-to-detect-if-the-browser-support-flash */
        if (typeof(window.ActiveXObject)!=="undefined") {
            try {
                /* IE */
                if (!!(new window.ActiveXObject("ShockwaveFlash.ShockwaveFlash")))
                    have_flash = true;
                }
            catch(e) { }
            }
        else
            have_flash = (typeof navigator.plugins != "undefined" && typeof navigator.plugins["Shockwave Flash"] == "object");
        var use_webrtc = have_webrtc/*tmp*/     /* whether we use webrtc (true) or flash (false) */
        var boxes_container = sel.find("div#boxes_container");
        $j('#people_toolbar').find('#people_view').buttonset().change(function(e){
            var tiled = $j('#tile',sel).button().is(':checked');
            if (tiled) {
                //boxes_container.show().next().hide();
                $j('.tile_view',sel).show();
                $j('.list_view',sel).hide();
                }
            else {
                //boxes_container.hide().next().show();
                $j('.tile_view',sel).hide();
                $j('.list_view',sel).show();
                }
            });
        $j('#people_toolbar').find('button').button();
        $j('#tile',sel).prop('checked',true).button('refresh').change();    // move this down further until after adding boxes and organize
        $j('#tile_organize',sel).click(function(){
            sort_boxes(undefined);
            });
/*
console.log( $j('#tile',sel) );
        $j('#tile',sel).prop('checked','checked');
        $j('#tile',sel).css('checked',true);
        $j('#tile',sel).css('checked','checked');
*/
        function box_by_user(u) {
            return boxes_container.find("div#box_"+u);
            }
        function box_by_listener(l) {
            if (typeof BRDashboard.listener_data[l] == 'undefined')
                return [];
            return box_by_user(BRDashboard.listener_data[l].user_id);
            }
        function sort_boxes(sortind/* unused for present */) {
            var wc=boxes_container.width();
            var boxes = $j('div.br-person-box,div.br-person-big-box',boxes_container), len=boxes.length, i;
            var arr = [];
            for(i=0; i<len; i++) {
                /* can't rely on .is(:visible) (or variants thereof) as parent (top bar tab) may not be visible */
                var elem = $j(boxes[i]), off=elem.offset(), visible=(elem.css('display')!=='none');
                if (visible)
                    arr.push($j.extend({},elem,{_y:off['top'],_x:off.left/* future: add name, other attrs */}));
                }
            arr.sort(function(a,b){ return (a._y===b._y)?(a._x-b._x):(a._y-b._y); /* future: different algorithm based on sortind */ });

            len = arr.length;
/* -- 
//seems to be much easier to stay with relative positioning ...
            /* 5,10 here is kinda play *./
            var xc=0,yc=5,miny=0;
            for(i=0; i<len; i++) {
                var e=arr[i], h=e.height(), x=xc, y=yc, miny;
                xc += e.width()+10;
                if (xc<wc) {
                    if (miny<h) miny=(h+10);
                    }
                else {
                    x = xc = 0;
                    yc += miny;
                    y = yc;
                    miny = (h+10);
                    } */
                /*if (e.css('position')!=='absolute') /* boxes start off with position relative *./
                    e.css('position','absolute'); *./
                //e.css({left:x,'top':y}); -- immediate
                e.animate({left:x,'top':y}); */



            for(i=0; i<len; i++) {
                var e=arr[i];
                e.animate({left:0,'top':0});    // -- this skips the whole logic and places relatively
                }
            }
/*
        function box2(u) {   // do depreciate and be careful of change in return value from null to []
            b = box_by_user(u);
            if (b.length) 
                return b;
            return null;
            }
*/
        function s(user_id,name) { return '#box_'+user_id+'_'+name; }
        function make_box(user_id) {
            var deferred_src = {};
            var box_id = 'box_' + user_id
                , title_id = box_id + '_title'
                , dtmf_id = box_id + '_dtmf__not_currently_used'
                , flash_id = box_id + '_flash'
                ;
            var my_broadcastable_stream_id = null;
            var other_persons_stream_id = null;
            var broadcasting = false;
            var viewing = false;
            /* margin here and "10" in sort_boxes() is play */
            boxes_container.append('\
<div id="'+box_id+'" class="br-person-box" style="margin: 4px; display: none;">\
<div class="ui-dialog-titlebar ui-widget-header ui-corner-top ui-helper-clearfix"><div style="float: left; padding-left: 5px;"><span id="'+title_id+'" style="overflow: hidden;">&nbsp;</span></div><div style="float: right; padding-right: 5px;"><!-- this is good, but still working on it ... <i class="icon icon-resize-full br-mini-button"></i><i id="foof" class="icon icon-reorder br-mini-button"></i>--><span id="'+dtmf_id+'"></span></div><div style="clear: all;"></div></div>\
<div class="ui-widget-content">\
<div id="avatar_parent">\
    <div id="video_parent" style="display: none;">\
        <video />\
    </div>\
    <div id="avatar_medium" style="display: none;"><img id="avatar_medium_img"><i class="icon icon-phone" style="font-size: 8em;"></i></div>\
    <div id="avatar_large" style="display: none;"><img id="avatar_large_img"><i class="icon icon-phone" style="font-size: 16em;"></i></div>\
</div>\
<span class="u-widget-header u-corner-all" style="padding: 10px 4px;">\
    <button id="talking" title="Audio Indicator">T</button>\
    <button id="mute" title="Mute">M</button>\
    <button title="Unmute">U</button>\
    <button id="start_webcam" title="Start My Webcam">B</button>\
    <button id="stop_webcam" title="Stop My Webcam">C</button>\
    <button id="start_video" title="View Webcam">S</button>\
    <button id="stop_video" title="Stop Viewing Webcam">H</button>\
    <button id="small" title="Normal Window">-</button>\
    <button title="Large Window">+</button>\
    <button id="select" title_disabled="Select">L</button>\
</span>\
</div>\
</div>'); 
            var b = box_by_user(user_id);
            //b.draggable({containment: "parent", scroll: false, stack: ".br-person-box", /*opacity: 0.5, /*helper: "clone",*./ grid: [100,100]*/});
            b.draggable({containment: "document", scroll: false, stack: ".br-person-box"/*, opacity: 0.5, /*helper: "clone",*./ grid: [100,100]*/});

            function do_webrtc(broadcast, stream_id) {
                /* under dev */
                wrapRTC.start({
                    broadcast: broadcast,
                    element: b.find('#video_parent > video').get(0),
                    stream_id: stream_id,
                    onSupportFailure: function(msg) { console.log(1,msg); },
                    onError: function(code) { console.log(2,code); },
                    signal: function(obj) { console.log(3,obj); }
                    });
                }

            function do_flash(broadcast, stream_id) {
                b.find('#avatar_parent').append('\
<div id="'+flash_id+'" style="display: none;">\
<h1>You need the Adobe Flash Player for this demo, download it by clicking the image below.</h1>\
            <p><a href="//www.adobe.com/go/getflashplayer"><img src="//www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" /></a></p>\
</div>\
');
                var flashvars = {
                    'csMediaServerURI':  BR.room.context.media_server_uri,
                    'csStreamId': stream_id
                    };
                var params = {
                    //bgcolor: '#282828'
                    };
                var attributes = {};
                swfobject.embedSWF( BR.api.v1.get_host('cdn') + "/v1/c/flash/" + (broadcast ? "brBroadcast.swf" : "brViewer.swf"),
                    //flash_id, "214", "160", "8.0.0", "expressInstall.swf", flashvars, params, attributes);  /* returns 'undefined' */
                    flash_id, "100%", "100%", "8.0.0", "expressInstall.swf", flashvars, params, attributes);  /* returns 'undefined' */
                if (broadcast)
                    BRCommands.videoAction(stream_id,true);
                }
            function update_webcam_buttons() {
                var flash_elem = b.find('#'+flash_id)
                    , on = flash_elem.length
                    , mbr = !!my_broadcastable_stream_id
                    , ops = !!other_persons_stream_id
                    ;
                BRUtils.ass(!(broadcasting && viewing));
/*
if (!ops) return;
console.log(other_persons_stream_id);
//b.find('#start_video').show();
console.log(b.find('.start_video'));
b.find('.start_video').show();
setTimeout(function(){ console.log('foobar',b.find('.start_video')); b.find('.start_video').show();}, 10000);
return;
*/
//console.log(broadcasting,viewing,on,mbr,ops);
                b.find('#start_webcam').hide().next().hide().next().hide().next().hide();
                if (viewing) {
                    BRUtils.ass(ops);
                    b.find('#stop_video').show();
                    }
                else if (broadcasting) {
                    BRUtils.ass(mbr);
                    b.find('#stop_webcam').show();
                    }
                else {
                    if (mbr && (have_webrtc || have_flash)) b.find('#start_webcam').show();
                    /*tmp*/else/*hack, read below*/if (ops && have_flash /*later: determine whether webrtc or flash*/) b.find('#start_video').show();
/* problem is old video K data lingers if the webcam is not closed by sender (i.e they just refresh the window).
need to change protocol to accomodate, perhaps just use gue or some such, might be easier all around
*/
                    }
                }
            function do_stop() {
                if (use_webrtc) {
                    }
                else {
                    var flash_elem = b.find('#'+flash_id);
                    if (flash_elem.length) {                                /* if we we're viewing/broadcasting webcam */
                        flash_elem.remove();
                        return true;
                        }
                    else    /* how would be get here? */
                        BRUtils.ass(false);
                    }
                return false;
                }
            function start_webcam_broadcast() {
                if (!my_broadcastable_stream_id) return;
                if (use_webrtc)
                    do_webrtc(true, my_broadcastable_stream_id);
                else 
                    do_flash(true, my_broadcastable_stream_id);
                broadcasting = true;
                update_webcam_buttons();
                show_avatar(false);
                }
            function stop_webcam_broadcast() {
                if (!do_stop()) return;
                show_avatar(true);
                BRCommands.videoAction(my_broadcastable_stream_id,false);    /* notify we've stopped broadcasting */
                broadcasting = false;
                update_webcam_buttons();
                }
            function start_webcam_view() {
                do_flash(false, other_persons_stream_id);
                viewing = true;
                update_webcam_buttons();
                show_avatar(false);
                }
            function stop_webcam_view() {
                if (!do_stop()) return;
                show_avatar(true);
                viewing = false;
                update_webcam_buttons();
                }
            function show_avatar(show) {
                if (show===undefined) /* check if video is on */
                    show = b.find('#'+flash_id).length ? false : true;  // || (broadcast || viewing) .. TODO tmp
                if (show) {
                    var av = $j((b.hasClass("br-person-big-box")?'#avatar_large':'#avatar_medium'),b)
                        img = $j('img',av);
                    if (img.prop('src'))
                        img.show().next().hide();
                    else
                        img.hide().next().show();
                    av.show();
                    }
                else
                    $j('#avatar_medium, #avatar_large',b).hide();
                }
            function avatar_icon_online(online) {
                var icon = 'icon-phone';
                if (online) {
                    icon = 'icon-user';
                    var iid = BRDashboard.invitee_id_by_user[user_id]
                        , i = BRDashboard.invitees[iid];
                    if (iid && i && i.role==="Host")
                        icon = 'icon-magic';
                    }
                b.find('#avatar_parent i.icon').removeClass('icon-user icon-phone').addClass(icon);
                }
            function other_persons_webcam_available(stream_id) {
//console.log(stream_id);
                if (stream_id) {
                    other_persons_stream_id = stream_id;
                    update_webcam_buttons();
                    }
                else {
                    /* kill any window ... */
                    other_persons_stream_id = null;
                    do_stop()
                    viewing = false;
                    update_webcam_buttons();
                    }
                }
            function audio_action(action) {
                var d = b.data('data').mids, mids = [];
                for(var m in d)
                    if (d.hasOwnProperty(m))
                        mids.push(m); 
                if (mids.length)
                    BRCommands.conferenceIdsAction(mids,action);
                }
            function resize(to_big) {
                show_avatar(false);
                if (to_big) {
                    b.removeClass("br-person-box").addClass("br-person-big-box");
                    //b.find("button:contains('-')").show().next().hide();
                    b.find("#small").show().next().hide();
                    }
                else {
                    b.removeClass("br-person-big-box").addClass("br-person-box");
                    //b.find("button:contains('-')").hide().next().show();
                    b.find("#small").hide().next().show();
                    }
                show_avatar(undefined);
                }
            b.find('#mute').parent().buttonset();
            b.find('#talking')
                //.button({label: '<i class="icon2-mute"></i>'}).show().next()
                .button({label: '<i class=""></i>'}).show().next()
                .button({label: '<i class="icon2-mic-off"></i>'}).click(function(){ audio_action('mute'); }).next()
                .button({label: '<i class="icon2-mic"></i>'}).click(function(){ audio_action('unmute'); }).next()
/*                .button({text: false, icons: { primary: "ui-icon-volume-on" }}).click(function(){ audio_action('mute'); }).next()
                .button({text: false, icons: { primary: "ui-icon-volume-off" }}).click(function(){ audio_action('unmute'); }).next() */
                //.button({ text: false, icons: { primary: "ui-icon-person" }}).click(function(){ WRONG,webcam_action(b); }).next()
                .button({label: '<i class="icon icon-facetime-video"></i>'}).click(function(){ start_webcam_broadcast(); }).next()
                .button({label: '<i class="icon icon-stop"></i>'}).click(function(){ stop_webcam_broadcast(); }).next()
                .button({label: '<i class="icon icon-eye-open"></i>'}).click(function(){ start_webcam_view(); }).next()
                .button({label: '<i class="icon icon-eye-close"></i>'}).click(function(){ stop_webcam_view(); }).next()
                //.button({ text: false, icons: { primary: "ui-icon-circle-minus" }}).click(function(){ resize(false); }).next()
                .button({label: '<i class="icon icon-resize-small"></i>'}).click(function(){ resize(false); }).next()
                //.button({ text: false, icons: { primary: "ui-icon-circle-plus" }}).click(function(){ resize(true); }).next()
                .button({label: '<i class="icon icon-resize-full"></i>'}).click(function(){ resize(true); }).next()
                // highlighting -- for referenceb.removeClass('ui-state-highlight'); b.addClass('ui-state-highlight');
                .button({label: '<!--<i class="icon2-check-empty"></i>-->'}).click(function(){ ; }).next()
                    ;
            //b.find(".ui-button-text").css('padding','0.4em');   /* no text in buttons: remove left, right padding around fontawesome icons */
            b.find(".ui-button-text").css({padding: '0.4em', height: '16px', width: '16px'});
   /* no text in buttons: remove left, right padding around fontawesome icons */
            b.find("button").hide();
            b.find("#talking,#select").show();
//console.log('did initial hide',user_id);
            //b.find("button:contains('+')").show();
            b.find("#small").next().show();
            show_avatar(true);
            update_webcam_buttons();
            BRDashboard.subscribe(function(o) {
                if (
                        (o.stream_id!=BR.room.context.connection_salt)  /* not our own webcam */
                        && (o.user_id==user_id)) {                      /* webcam for this box (user_id matches) */
//console.log(o);
                    if (typeof(o.data)!=='undefined')
                        other_persons_webcam_available(o.stream_id);
                    else
                        other_persons_webcam_available(null);         /* stop viewing webcam */
                    }
                },'video');


            /* === the somewhat complex interplay of talking / muting etc. etc. */
            var lmut_store = {};
            function lmut(listening,mute,talking,is_host){
//console.log(listening,mute,talking,is_host);
                if (typeof(listening)!=="undefined") lmut_store.listening = listening;
                if (typeof(mute)!=="undefined") lmut_store.mute = mute;
                if (typeof(talking)!=="undefined") lmut_store.talking = talking;
                if (typeof(is_host)!=="undefined") lmut_store.is_host = is_host;
                b.find('#talking i').removeClass('icon2-volume-off icon2-volume-up')
                b.find('#mute').hide().next().hide();
                if (lmut_store.listening) {
                    var nc = '';
                    if (lmut_store.talking) nc = 'icon2-volume-up';
                    else if (lmut_store.mute) nc = 'icon2-volume-off';
                    if (nc.length) b.find('#talking i').addClass(nc);
                    var sel = b.find('#mute');
                    if (lmut_store.mute) sel = sel.next();
//console.log("option", BR.room.context.user_id,user_id,lmut_store.is_host);
                    sel.show().button((BR.room.context.user_id==user_id || lmut_store.is_host) ? "enable" : "disable");
                    }
                }
            BRDashboard.subscribe(function(o){
                if (o.updated.is_host)
                    lmut(undefined, undefined, undefined, BR.room.context.is_host);
                },'room_context');
            lmut(false, false, false, BR.room.context.is_host); /* initial setup */
            b.data('lmut',lmut);
            /* === end of somewhat complex interplay ... */


            b.data('cb',function(verb,key,value){
                switch(verb){
/*
                    case 'show':
                        if (deferred_src) {
                            deferred_src.avatar_medium && b.find('#avatar_medium_img').prop('src',deferred_src.avatar_medium);
                            deferred_src.avatar_large && b.find('#avatar_large_img').prop('src',deferred_src.avatar_large);
                            deferred_src = {};
                            show_avatar(undefined);
                            }
                        avatar_icon_online(value.data._online);
                        b.show();
                        break;
                    case 'hide':
                        avatar_icon_online(value.data._online);
                        b.hide();
                        break;
*/
                    case 'src':
                        if (b.is(':visible')) {
                            b.find('#'+key+'_img').prop('src',value);
                            show_avatar(undefined);
                            }
                        else
                            deferred_src[key] = value;
                        break;
/*
                    case 'update':
//console.log(value);
                        if (value.data.dtmf !== value.old_data.dtmf)
                            //b.find('#'+dtmf_id).text(value.data.dtmf ? value.data.dtmf : ''); -- display digits -- all others clear
                            b.find('#'+dtmf_id).text((parseInt(value.data.dtmf)||0) ? value.data.dtmf : '');
                            //b.find('#'+dtmf_id).html(value.data.dtmf ? '&#x246'+(parseInt(value.data.dtmf)-1).toString() : ''); /* overkill, too small to read, support? *./
                        if (value.data._online !== value.old_data._online) {
                            avatar_icon_online(value.data._online);
//console.log(value);
                            }
                        break;
*/
                    }
                });
            b.data('box_function',function(o){
                /* better than the above function, pre-selected for this box only */
                switch(o.command) {
                    case 'show':
                        if (deferred_src) {
                            deferred_src.avatar_medium && b.find('#avatar_medium_img').prop('src',deferred_src.avatar_medium);
                            deferred_src.avatar_large && b.find('#avatar_large_img').prop('src',deferred_src.avatar_large);
                            deferred_src = {};
                            show_avatar(undefined);
                            }
                        avatar_icon_online(o.data._online);
                        b.show();
                        break;
                    case 'hide':
                        avatar_icon_online(o.data._online);
                        b.hide();
                        break;
                    case 'update':
                        if (o.data.dtmf !== o.old_data.dtmf)
/*
                            b.find('#'+dtmf_id).text((parseInt(o.data.dtmf)||0) ? o.data.dtmf : '');
                            //b.find('#'+dtmf_id).html(o.data.dtmf ? '&#x246'+(parseInt(o.data.dtmf)-1).toString() : ''); /* overkill, too small to read, support? *./
*/
                            //b.find('#'+dtmf_id).text((parseInt(o.data.dtmf)||0) ? o.data.dtmf : '');
                            //b.find('#select').button("option", "label", o.data.dtmf ? '&#x246'+(parseInt(o.data.dtmf)-1).toString() : '');
                            var dtmf_tmp = (parseInt(o.data.dtmf)||0);
                            if (dtmf_tmp>0) dtmf_tmp = '&#x246'+((dtmf_tmp-1).toString());
                            //if (dtmf_tmp>0) ; //dtmf_tmp = '&#x246'+((dtmf_tmp-1).toString());
                            else dtmf_tmp = '';//(o.data.dtmf || ''); -- don't display 0, #, *
                            b.find('#select span').html('<span style="font-weight: bold; font-size: 1.1em;">' + dtmf_tmp + '</span>'); /// -- too ginicky
                            //b.find('#select span').html('<span style="font-weight: bold;">' + dtmf_tmp + '</span>');
                        if (o.data._online !== o.old_data._online) {
                            avatar_icon_online(o.data._online);
                            }
                        if (BRDashboard.connection_id) {
                            var salt = (BRDashboard.connection_id in o.data.connection_ids) ? BR.room.context.connection_salt : null;
                            if (salt!==my_broadcastable_stream_id) {
                                my_broadcastable_stream_id = salt;
                                update_webcam_buttons();
                                }
                            if (o.data._online!==o.old_data._online && o.id)
                                b.find('#'+title_id).html(BRWidgets.user_name(o.data.connection_ids,o.id));
                            }
                        break;
                    }
                if (!o.old_data._listeners && o.data._listeners)
                    lmut(true, undefined, undefined, undefined);
                else if (o.old_data._listeners && !o.data._listeners)
                    lmut(false, undefined, undefined, undefined);
                });
            return b;
            }
function _2delete_me(){
        BRDashboard.subscribe(function(o){
            var b = [];
            switch(o.command) {
                case 'mod':
/*
can't operate on individual connections as the last one will always overwrite...
                    b = box_by_user(o.user_id);
                    if (b.length && typeof(o.connection_id)!=='undefined') {
                        b.find(s(o.user_id,'title')).html(BRWidgets.user_name([o.connection_id],o.user_id));
                        if (BRDashboard.connection_id==o.connection_id) /* little bit of a hack *./
                            b.find('#mute').next().next().show(); NOW wrong
                        }
*/
                    break;
                case 'del':
/* need to add this, but not sure it's right ...
                    b = box_by_user(o.user_id);
                    b.remove(); */
                    break;
                }
            },'online');
}
/* playing ...
        BRDashboard.subscribe(function(o){
            if (o.updated.is_live && BR.room.context.is_live) { /* we just went live *./
                }
            },'room_context');
*/
        BRDashboard.subscribe(function(o){
            var b = box_by_user(o.idx);
            if (b.data('data') && ('connection_ids' in b.data('data')) && (typeof o.attr != 'undefined'))
                b.find(s(o.idx,'title')).html(BRWidgets.user_name(b.data('data')['connection_ids'],o.idx));
// TODO tmp.... when we delete an image?
            if (o.idx && o.attr && o.value) {
                if (o.attr==='avatar_medium' || o.attr==='avatar_large')
                    b.data('cb')('src',o.attr,o.value);
                }
            },'users');
/*        BRDashboard.subscribe(function(o){
            /*var selected = (grid.jqGrid('getGridParam','selarrrow').indexOf(o.id)>-1);
            if (selected != o.selected)
                grid.jqGrid('setSelection',o.id,false);
            *./},'select_listener'); */
        BRDashboard.subscribe(function(o){
            var b = box_by_listener(o.mid);
            if (b.length && o.command=='attr' && (typeof(o.attrs['mute'])!==undefined))
                b.data('lmut')(undefined, o.attrs.mute ? true : false, undefined, undefined);
            },'listener');
        BRDashboard.subscribe(function(o){
            var b = box_by_listener(o.mid);
            if (!b.length) 
                return;
            b.data('lmut')(undefined, undefined, typeof(o.value)==='undefined' ? false :true, undefined);
            },'talking');
/*
        BRDashboard.subscribe(function(o){
            if (!o.updated.is_host) return;
            var b = box_by_user(o.idx);
            }, 'room_context'); */
        BRDashboard.subscribe(function(o){
            var b = box_by_user(o.data['user_id']);
            switch(o.command) {
                case 'add':
                    b = make_box(o.data['user_id']);
                    break;
                case 'del':
                    break;
/*
                case 'show':
                    b.data('cb')('show',null,o);
                    break;
                case 'hide':
                    b.data('cb')('hide',null,o);
                    break;
                case 'update':
                    b.data('cb')('update',null,o);
                    break;
*/
                }
            if (b.length) {
                b.data('data',o.data);
                b.data('box_function')(o);
/*
                if (!o.old_data._listeners && o.data._listeners)
                    b.find('#mute').show();     // audio now attached
                else if (o.old_data._listeners && !o.data._listeners)
                    b.find('#mute').hide().next().hide();     // audio now deattached
*/
                }
            },'box');
    },

    slidesArea: function(sel) {
        var $j = jQuery;
        var have_moved_user_to_slideshows_once = false;
        $j(sel).append('<center>'+BRWidgets._commonToolbar('slides_toolbar')+'<div style="height: 2px;"></div><div id="slide" class="br-z-index-slide"><img id="slide_img" width="800" alt="" class="ui-widget-content" style="cursor: crosshair;"></div></center>');
        $j(sel).append('<div id="cslptr" class="br-z-index-ptr" style="position: absolute; background-color: transparent; color: red; padding: 0; margin: 0; font-size: 2em; display: none; cursor: crosshair; pointer-events: none;">&otimes;</div>');
        var no_pres_text = '-- No Presentation Loaded --';
        var sel_pres_text = '-- Select a Presentation --';
        $j('#slides_toolbar').append('\
<span class="not_presenting">\
    <span><a href="#" target="_blank" id="presentation_name">'+no_pres_text+'</a></span>\
    <span id="page">--</span>\
</span>\
<span class="presenting">\
    <select id="presentations"><option value="-1">'+sel_pres_text+'</option></select>\
    <button id="upload_button" title="Upload file...">Upload</button>\
    <select id="current_page"><option>--</option></select>\
</span>\
<span>\
    <span>/ </span>\
    <span id="num_pages">--</span>\
</span>\
<span class="presenting">\
    <button id="beginning_button" class="page_control goes_forward" title="First">First</button>\
    <button class="page_control goes_forward" title="Prev">Prev</button>\
    <button id="show_button"  class="page_control" style="" title="Show Slide"><i class="icon icon-eye-open"></i></button>\
    <button id="hide_button"  class="page_control" style="display: none;" title="Hide Slide"><i class="icon icon-eye-close"></i></button>\
    <button class="page_control goes_backward" title="Next">Next</button>\
    <button class="page_control goes_backward" title="End">End</button>\
    &nbsp;\
    <button title="Close Presentation">Close</button>\
</span>\
<span id="presenter" class="not_presenting">\
</span>\
<button id="make_me_button" class="not_presenting">Make Me Presenter</button>\
');
        $j('#upload_button').button({ text: false, icons: { primary: "ui-icon-circle-arrow-n" }}).click(BRWidgets._upload);
        var current_page = $j('#current_page');
        BRWidgets.styleSelect(current_page);
        $j('#beginning_button')
            .button({ text: false, icons: { primary: "ui-icon-seek-first" }}).click(function(){
                presenter_set_page(1);
                }).next()
            .button({ text: false, icons: { primary: "ui-icon-seek-prev" }}).click(function(){
                presenter_set_page(-1);
                }).next()
            .button({ text: true, no_icons: { primary: "ui-icon-play" }}).click(function(){
                BRCommands.slideAction('show', current_page.val());
                }).next()
            .button({ text: true, no_icons: { primary: "ui-icon-stop" }}).click(function(){
                BRCommands.slideAction('show', undefined);
                }).next()
            .button({ text: false, icons: { primary: "ui-icon-seek-next" }}).click(function(){
                presenter_set_page(0);
                }).next()
            .button({ text: false, icons: { primary: "ui-icon-seek-end" }}).click(function(){
                presenter_set_page($j('#num_pages').text());
                }).next()
            .button({ text: false, icons: { primary: "ui-icon-closethick" }}).click(function(){
                BRCommands.slideAction(undefined, undefined);
                }).next()
            ;
        $j('#make_me_button')
            .button({ text: true, no_icons: { primary: "ui-icon-pencil" }})
            .click(function(){
                BRCommands.slideAction('presenter', BR.room.context.user_id + ':' + BR.room.context.user_name);
            })
          /*  .tooltip(); */
            ;
        /* --- put this back in when "anyone may present" is a conference option
        if (!is_host)
            $j('#make_me_button').css('display','none');
        */

        var presentations = [];
        var sel_pr = $j('#presentations');
        BRWidgets.styleSelect(sel_pr);
        BRWidgets.enableSelect(sel_pr,false);
        var url;
        var mp_url;
        function update_page_controls() {
            var page = parseInt(current_page.val(), 10) || 0;
            var num_pages = parseInt($j('#num_pages').text(), 10) || 0;

            if (page>0) {
                // start by enabling everything
                $j(sel).find("button.page_control").button("enable");
                // the removeClass() hijinx here is b/c of a jQuery bug which doesn't remove hover/focus state when disabling buttons
                if (page==1)
                    $j(sel).find("button.goes_forward").removeClass('ui-state-focus ui-state-hover').button("disable");
                if (page==$j('#num_pages').text())
                    $j(sel).find("button.goes_backward").removeClass('ui-state-focus ui-state-hover').button("disable");
                }
            else
                $j(sel).find("button.page_control").button("disable");
            }
        function set_presentation(data) {   /* when we get notification of a presentation change, or init, or reset */
            var arr = data.match(/^([^:]+):([^:]+):([^:]+):(\d):(.+)$/);
            show_page(0);
            current_page.find('option').remove();
            // the second check here is because this slide may have been deleted
            if (arr && sel_pr.find('option[value="'+arr[2]+'"]').length) {
                var num_pages = arr[1];
                $j('#num_pages').text(num_pages);
                if (num_pages>0) {
                    for(var i=1; i<=num_pages; i++) {
                        current_page.append('<option value="'+i+'">'+i+'</option>');
                        }
                    BRWidgets.enableSelect(current_page,true);
                    }
                var presentation_name = unescape(arr[3]);
                sel_pr.val(arr[2]);
                url = arr[5];
                $j('#presentation_name').text(BRWidgets._crop(presentation_name));
                $j('#presentation_name').attr('href',url);
                $j('#presentation_name').attr('title','Download ' + presentation_name);
                if (arr[4]==1)     /* multipage */
                    mp_url = url.replace(/\.([^\/]*)\?\d*$/,'_$1');
                else
                    mp_url = '';
/*                $j(sel).find("button.page_control").button("enable"); */
                update_page_controls();
                }
            else {
//console.log('set_presentation(undefined)');
                $j('#num_pages').text("--");
                $j('#presentation_name').text(no_pres_text);
                $j('#page').text('');
                current_page.append('<option>--</option>');
                BRWidgets.enableSelect(current_page,false);
                sel_pr.val('-1');
                url = '';
                mp_url = '';
/*                $j(sel).find("button.page_control").button("disable"); */
                update_page_controls();
                }
            }

        function presenter_set_page(new_page_num) {   /* when presenter changes page */
            if (typeof(new_page_num)== 'string') {
                new_page_num = parseInt(new_page_num, 10);
                if (isNaN(new_page_num))
                    return;
                }
            if (new_page_num<1) {
                var page = parseInt(current_page.val(), 10);
                if (isNaN(page))
                    return;
                if (new_page_num==-1)
                    new_page_num = (page-1);
                else if (new_page_num==0)
                    new_page_num = (page+1);
                else
                    return;
                }
            var num_pages = $j('#num_pages').text();
            if (new_page_num<1 || new_page_num>num_pages)
                return;
            current_page.val(new_page_num);
            update_page_controls();
            if ($j('#show_button').css('display')=='none')
                BRCommands.slideAction('show', new_page_num);
            }

        var selImg = $j('#slide_img');
        var selPtr = $j('#cslptr');
        function show_page(page_num) {
            // the second check here is because that file/presentation may have been deleted
            if (page_num && current_page.find('option[value="'+page_num+'"]').length) {
                current_page.val(page_num);
                $j('#page').text(page_num);
                $j('#show_button').css('display','none');
                $j('#hide_button').css('display','inline');
                var surl;
//console.log(mp_url.length);
                if (mp_url.length)
                    surl = mp_url + '-' + page_num + '.png';
                else
                    surl = url;
//console.log(surl);
                selImg.css('display','block').attr('src',surl.replace(/^https?:/,''));
                selPtr.css('display','block');

                $j(sel).find("button.page_control").button("enable");
                update_page_controls(); // TODO working on this ...
/*
                $j('#slide').mousemove(function(e){
//                    console.log([(new Date).getTime(),e.pageX,e.pageY,e.clientX,e.clientY]);
                    });
*/

                /* fetch next slide into cache? */
/*
-- doesn't seem to work so well ...
... and now it's quite old also ...
                var num_pages = $j('#num_pages').text();
                if (num_pages>page_num) {
                    surl = url + '-' + (page_num+1) + '.png';
                    $j('#next_slide').html('<img src="' + surl + '" alt="">');
                    }
*/
                /* move user to slideshow (once only) */
                if (!presenting() && !have_moved_user_to_slideshows_once) {
                    switch_view('slides');  /* barrowed from workspace */
                    have_moved_user_to_slideshows_once = true;
                    }
                if (ticking===undefined)
                    ticking = setInterval(fnTick,40);
                }
            else {
                update_page_controls(); // TODO working on this ...
                $j('#show_button').css('display','inline');
                $j('#hide_button').css('display','none');
                //$j('#slide').html('');
                selImg.css('display','none');
                selPtr.css('display','none');
//                $j('#slide').css('cursor','default').find('img').css('display','none');
                if (ticking!==undefined) {
                    clearInterval(ticking);
                    ticking = undefined;
                    }
                }
            }

        sel_pr.prop('disabled',true).change(function(){
            var selIndex = sel_pr.find(':selected').val();
            if (selIndex!='') {
/*
                var len = presentations.length;
                var mf = undefined;
*/
                var mf = presentations[selIndex].media_file;
/*
                for(var i=0; i<len; i++) {
                    if (presentations[i].media_file.id==selIndex) {
                        mf = presentations[i].media_file;
                        break;
                        }
                    }
*/
                if (mf) {
                    var last_page = mf.slideshow_pages;
                    BRCommands.slideAction('presentation', mf.slideshow_pages + ':' + mf.id + ':' + escape(mf.name) + ':' + (mf.multipage?1:0) + ':' + mf.url);
                    }
                }
            });
        current_page.change(function(){
            presenter_set_page(current_page.val());
            });
        set_presentation('');
        BRDashboard.subscribe(function(h){
            if (h.attr===undefined && h.value===undefined) {
                if (presentations[h.idx] !== undefined) {
//console.log('0=' + sel_pr.val());
//console.log('1=' + h.idx);
                    if (sel_pr.val()==h.idx) /* if currently selected? */
                        set_presentation('');
                    sel_pr.find('option[value="' + h.idx + '"]').remove();
                    delete presentations[h.idx];
                    }
                }
            else {
                if (presentations[h.idx] === undefined)
                    presentations[h.idx] = {media_file:{id:h.idx}};
                presentations[h.idx].media_file[h.attr] = h.value;
                var mf = presentations[h.idx].media_file;
                if (mf.name && mf.url && mf.slideshow_pages>0 && !sel_pr.find('option[value="'+ h.idx + '"]').length) {
                    sel_pr.append('<option value="'+mf.id+'">'+BRWidgets._crop(mf.name)+'</option>');
                    BRWidgets.enableSelect(sel_pr,true);
                    }
                }
            },'media_files');

        var pointerXY = {x:0,y:0};
        var pointing = false;
        function set_ptr(value) {
            if (value) {
                if (!/^(\d+),(\d+)$/.exec(value))
                    return;
                var x = RegExp.$1;
                var y = RegExp.$2;
                pointerXY = adjustOutPtr({x:parseInt(x, 10),y:parseInt(y, 10)});
                }
            else
                selPtr.css('display','none');
            rlIn = 0;
            }
        var lastPointerTime = 0;    // don't need to reset this
        function fnMM(e) {
//console.log(e);
            lastMMEvent = e;
//console.log([0,lastMMEvent.csX,lastMMEvent.csY]);
            lastMMEvent.csX = lastMMEvent.pageX - Math.round(selImg.offset().left),
            lastMMEvent.csY = lastMMEvent.pageY - Math.round(selImg.offset().top),
//console.log([1,lastMMEvent.csX,lastMMEvent.csY]);
            lastMMEventTime = (new Date).getTime();
            }
        function adjustOutPtr(pair) {
//console.log([2,pair.x,pair.y]);
            /* the +2, -2 adjustments here are the official fudge factors */
            // why whole numbers? pair.x += (Math.round(selImg.offset().left) - Math.round($j('#slide').offset().left)) - Math.ceil(selPtr.width()/2) + 1.5;
            //pair.x += ((selImg.offset().left - $j('#slide').offset().left) - (selPtr.width()/2)) + 1.5;
// hacking around here a bit ...
            pair.x += ((selImg.offset().left - $j('#slide').offset().left) - (selPtr.width()/2)) + 1.0;

            //pair.y += (Math.round(selImg.offset().top) - Math.round($j('#slide').offset().top)) - 2;//Math.ceil(selPtr.height()/2);
//console.log($j('#slide').offset());
//console.log($j('#slide').position());
//console.log(selImg.position());
//console.log(selImg.offset());
            //pair.y += (Math.round(selImg.offset().top) - Math.round($j('#slide').offset().top)) - 2;//Math.ceil(selPtr.height()/2);
            pair.y += (Math.round(selImg.offset().top) - 0) - 10;//Math.ceil(selPtr.height()/2);
            return pair;
            }
        var ticking = undefined;
        var lastPointerSendTime = 0;
        var lastMMEventTime = 0;
        var lastMMEvent = {};
        var xyAtLastSend = {};
        function point() {
            if (!lastMMEventTime)
                return;
//console.log(0,xyAtLastSend,lastMMEvent);
            if (xyAtLastSend.x==lastMMEvent.csX && xyAtLastSend.y==lastMMEvent.csY)
                return;
            else 
                xyAtLastSend = {};
//console.log(3,xyAtLastSend,[lastMMEvent.csX,lastMMEvent.csY],xyAtLastSend.x===lastMMEvent.csX,xyAtLastSend.y===lastMMEvent.csY);

            /* give immediate feedback to presenter, comment this out to have presenter see the same thing everyone else does */
            pointerXY = adjustOutPtr({x:lastMMEvent.csX,y:lastMMEvent.csY});
//console.log(2,pointerXY);

            var now = (new Date).getTime();
            if ((now - lastPointerSendTime)<200)    // too soon
                return;

            BRCommands.slideAction('ptr', lastMMEvent.csX + ',' + lastMMEvent.csY);
            lastPointerSendTime = now;
            xyAtLastSend = {x:lastMMEvent.csX,y:lastMMEvent.csY};
            }
        var deltaXY = {x:0,y:0};
        var dampFactor = 4;
        function fnTick() {
            if (pointing)
                point();
            deltaXY.x += (pointerXY.x - deltaXY.x) / dampFactor;
            deltaXY.y += (pointerXY.y - deltaXY.y) / dampFactor;
//console.log(1,[deltaXY.x, deltaXY.y]);
            selPtr.css({left: deltaXY.x+'px', top: deltaXY.y+'px'});
            }
        function presenting() {                 /* determine if we are currently presenting -- TODO optimize? */
            return ($j('.presenting').css('display')!=='none');
            }
        function startStopPointer() {
            var showingPage = ($j('#slide').html().length>0);
            if (presenting() && showingPage && !pointing) {
                pointing = true;
                $j('#slide_img').bind('mousemove',fnMM);
/*                $j('#slide_img').bind('touchmove',function(e){ -- leaving this out until I know how to use it correctly 
                    e.preventDefault();
                    fnMM(e);
                    }); */
                }
            if (pointing && !(presenting() && showingPage)) {
                pointing = false;
                $j('#slide_img').unbind('mousemove',fnMM);
                //$j('#slide_img').unbind('mousemove touchmove',fnMM);
                }
            }
        
        BRDashboard.subscribe(function(o){
            switch(o.variable) {
                case 'presenter':
                    if (o.value) {
                        var arr = o.value.match(/^\s*([^:]+):(.*)$/);
                        if (arr && arr.length==3) {
                            //$j('#presenter').text(' Presenter: ' + arr[2] + ' '); -- try the look below for a while ...
                            $j('#presenter').html(' <em>Presenter:</em> ' + arr[2] + ' ');
                            if (arr[1] == BR.room.context.user_id) {    /* we are presenting */
                                $j('.not_presenting').css('display','none');
                                $j('.presenting').css('display','inline');
                                }
                            else {                              /* somebody else presenting */
                                $j('.presenting').css('display','none');
                                $j('.not_presenting').css('display','inline');
                                }
                            }
                        }
                    break;

                case 'presentation':
                    set_presentation(o.value);
                    break;

                case 'ptr':
                    set_ptr(o.value);
                    return;     /* skip startStopPointer() at end */

                case 'show':
                    show_page(o.value);
                    break;

                case undefined:
                    if (o.value==undefined) {   /* reset */ // tmp TODO. working on this ...
                        $j('#presenter').text('');
                        $j('.not_presenting').css('display','inline');
                        $j('.presenting').css('display','none');
                        set_presentation('');
                        }
                    break;
                }
            startStopPointer();
            },'slide');
        $j('.presenting').css('display','none');
    },

/*
    listArea: function(sel) {
        var $j = jQuery;
        $j(sel).append('<center><table id="center_grid"></table></center>');
        BRParticipants.openParticipantWindow2($j('#center_grid'));

        /* hack to hide horizontal scroll bar, may not work on all browsers *./
        $j(sel).find('div .ui-jqgrid-bdiv').css('overflow-x','hidden');
    },
*/

    changeCenterView: function(view) {
        var $j = jQuery;
        $j('#center_slides').css('display','none');
        $j('#center_people').css('display','none');
        $j('#center_list').css('display','none');
        $j('#center_'+view).css('display','block');
    },

    content_participantSummary: function(id,selector) {
        var accStr = '<div id="'+selector+'" style="overflow: hidden;">';
        accStr += '<div><table id="right_listeners_table"></table></div>';
        accStr += '<div><table id="'+id+'_right_online_table"></table></div>';
        accStr += '</div>';
        return accStr;
    },

    participantSummary: function(id,selector) {
        var $j = jQuery;
        function modified() { BRWidgets._modified($j(selector).prev().data('key',id+'_participants')); }
        var t = $j('#'+id+'_right_online_table');
        t.jqGrid({
            datatype: "local",
            colModel:[
                {name:'id', hidden: true, sorttype:"int"},
                {name:'full_name', label:'Online'},
                {name:'user_id', hidden: true, sorttype:"int"}
                ],
            width: 175
            });

        function fixup_name(connection_id,user_id) {
            var cids  = {};
            cids[connection_id] = true;
            t.jqGrid('setRowData',connection_id,{full_name:BRWidgets.user_name(cids,user_id)});
            }
        BRDashboard.subscribe(function(o){
            switch(o.command) {
                case 'mod':
                    if (!t.jqGrid('getInd',o.connection_id))    // don't use getRowData here, (misdocumented) nightmare
                        t.jqGrid('addRowData',o.connection_id,{id:o.connection_id,user_id:o.user_id});
                    fixup_name(o.connection_id,o.user_id);
                    break;
                case 'del':
                    t.jqGrid('delRowData',o.connection_id);
                    break;
                }
            /* modified(); -- skip this for the present as (1) it is noisy and (2) "disconnection" bug makes it show up annoyingly */
            modified();
            },'online');
        BRDashboard.subscribe(function(o){
            if (o.attr!='name' && o.attr!='last_name')
                return;
            var rows = t.jqGrid('getRowData');
            for(var i=0; i<rows.length; i++) {
                if (o.id == rows[i].user_id)
                    fixup_name(rows[i].id, o.id);
                }
            },'users');

        function callers_change() {
            if (BRDashboard.listeners.length)
                $j('button.need1caller').button("enable");
            else
                $j('button.need1caller').button("disable");
            modified();
            }
        BRDashboard.subscribe(callers_change,'listener');
        callers_change();
    },

    content_files: function(id,selector) {
        var accStr = '<div id="'+selector+'">';
        accStr += '<div><table id="'+id+'_files"></table></div>';
        accStr += '\
    <div style="height: 5px"></div>\
    <fieldset id="'+id+'_fieldset" class="ui-widget ui-widget-content"><legend id="'+id+'_selected" class="ui-widget-header ui-corner-all"></legend>\
        <div id="'+id+'_fields"></div>\
        <div style="float: left;"><button id="'+id+'_download" style="width: 75px;" title="Open file"><a id="'+id+'_url" target="_blank" href="">Open</a></button></div>\
        <div style="float: right;"><button id="'+id+'_delete" style="width: 75px;" title="Delete file">Delete</button></div>\
        <div style="clear: both;"></div>\
    </fieldset>\
    <div style="height: 5px"></div>\
    <center><button id="'+id+'_upload" style="width: 75px;" title="Upload file...">Upload...</button></center>\
    ';
        accStr += '</div>';
        return accStr;
    },

    files: function(id,selector) {
        var $j = jQuery;
        var t = $j('#'+id+'_files');
        $j('#'+id+'_download').button({ text: true, icons: { primary: "ui-icon-arrowthickstop-1-s" }});
        $j('#'+id+'_delete').button({ text: true, icons: { primary: "ui-icon-trash" }}).click(function(){
            if (confirm("The selected file will be permanently deleted. Press OK to confirm.")) {
                var rowid = t.jqGrid('getGridParam','selrow');
                if (!rowid) return;
                function done(data, textStatus, jqXHR) {
                    if (rowid /* still */ == t.jqGrid('getGridParam','selrow'))
                        $j('#'+id+'_delete').button("enable");
                    switch(textStatus) {
                        case 'success':
                            //alert('File deleted. The file list will update momentarily.');
                            break;
                        case 'error':
                            alert("An error occurred deleting file.\n\nYou may not have permission to delete this file.");
                            break;
                        }
                    }
                $j('#'+id+'_delete').button("disable");
                jQuery.ajax({
                    url: '//myapi.babelroom.com/plugin/0/media_files/' + rowid + ".js",
                    type: "DELETE",
// BRInvitees.aj("/invitations/add_guest.js", {invitation:{conference_id:BR.room.context.conference_id}, user:{}, auth: BR.room.context.authen}, function(data, textStatus, jqXHR){
                    //data: un,
                    success: done,
                    xhrFields: {
                        withCredentials: true
                        },
                    error: function (jqXHR, textStatus, errorThrown) { done(errorThrown, textStatus, jqXHR); }
                    });
                }
            });
        $j('#'+id+'_upload').button({ text: true, icons: { primary: "ui-icon-circle-arrow-n" }}).click(BRWidgets._upload);
        t.jqGrid({
            datatype: "local",
            colModel:[
                {name:'id', index:'id', hidden: true, sorttype:"int"},
                {name:'name', label:'Download'},
                {name:'pages', label:'Pages', width:'50', align:'right'},
                {name:'url', hidden: true},
                {name:'bucket', hidden: true},
                {name:'len', hidden: true},
                {name:'size', hidden: true},
                {name:'user_id', hidden: true}
                ],
            onSelectRow: function(rowid,selected) {
                var rd = t.jqGrid('getRowData',rowid);
                $j('#'+id+'_selected').text(BRWidgets._crop(rd.name,28)).attr('title',rd.name);
                $j('#'+id+'_fieldset').find("button").button("enable");
                $j('#'+id+'_url').attr("href",rd.url);
                var f = '';
                function size(i) {
                    var s = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
                    var e = Math.floor(Math.log(i)/Math.log(1024));
                    return (i/Math.pow(1024, Math.floor(e))).toFixed(2)+" "+s[e];
                    }
                if (rd.name)
                    f += '<div style="float:left;width:30px;"><b>Name:</b></div><div style="float:right;width:110px;" title="'+rd.name+'">'+BRWidgets._crop(rd.name,22)+'</div><div style="clear:both;"></div>';
                if (rd.bucket)
                    f += '<div style="float:left;width:30px;"><b>Bucket:</b></div><div style="float:right;width:110px;">'+rd.bucket+'</div><div style="clear:both;"></div>';
                if (rd.len)
                    f += '<div style="float:left;width:30px;"><b>Length:</b></div><div style="float:right;width:110px;">'+rd.len+'</div><div style="clear:both;"></div>';
                if (rd.size)
                    f += '<div style="float:left;width:30px;"><b>Size:</b></div><div style="float:right;width:110px;">'+size(rd.size)+'</div><div style="clear:both;"></div>';
                $j('#'+id+'_fields').html(f);
                },
            width: 175
            });
        function unselected() {
            $j('#'+id+'_selected').text('No file selected').attr('title','');
            $j('#'+id+'_download').button("disable");
            $j('#'+id+'_delete').button("disable");
            $j('#'+id+'_fields').html('');
            }
        unselected();
        function modified() { BRWidgets._modified($j(selector).prev().data('key',id+'_files')); }
        function cb(h) {
            if (h.attr===undefined && h.value===undefined) {
                if (t.jqGrid('getGridParam','selrow')==h.id)
                    unselected();
                t.jqGrid('delRowData',h.id);
                modified();
                }
            else {
                if (!t.jqGrid('getInd',h.id)) {
                    t.jqGrid('addRowData',h.id,{name:'-'});
                    modified();
                    }
                var tmp;
                switch(h.attr) {
                    case 'url': t.jqGrid('setRowData',h.id,{url:h.value}); break;
                    case 'name': t.jqGrid('setRowData',h.id,{name:h.value}); break;
                    case 'bucket': t.jqGrid('setRowData',h.id,{bucket:h.value}); break;
                    case 'length': t.jqGrid('setRowData',h.id,{len:h.value}); break;
                    case 'size': t.jqGrid('setRowData',h.id,{size:h.value}); break;
                    case 'slideshow_pages':
                        switch(h.value) {
                            case undefined: tmp = '???'; break;
                            case '-1': tmp = '<img src="/v1/c/img/arrows_spinner.gif" alt="Loading...">'; break;
                            case '0': tmp = '<em>None</em>'; break;
                            default: tmp = h.value;
                            };
                        t.jqGrid('setRowData',h.id,{pages:tmp});
                        break;
                    default:
                        return;
                    }
                modified();
                }
            }
        BRDashboard.subscribe(cb,'media_files');
    },

    commonSelectedHandler: function(selector,data) {
        var $j = jQuery;
        var sel = BRDashboard.selectedListeners.length;
        var text = '.';
        var t;
        switch(sel) {
            case 0: text = 'No participants selected'; break;
            case 1: if ((t=BRDashboard.listener_data[data.id])) { text=t.name; break; }
            /* else fall thru .. */
            default: text = sel.toString(10) + ' participants selected';
            }
        $j('#'+selector).text(text);
        return sel;
    },

    dialerMonitor: function(root_selector,selector) {
        var id = BRWidgets.nextId();
        var $j = jQuery;
        function modified() { BRWidgets._modified(jQuery(root_selector).prev().data('key',id+'_dialpad'/*'_monitor'*/)); }
        var text = function(msg, token, color) {
            var elem_id = '#'+id+'_'+token+'_status';
            var elem = $j(elem_id);
            if (!elem.length)
                return;
            elem.html(msg);
            if (color) {
                //elem.css('background-color',color);
                elem.css('color',color);
                }
            }
        var d = jQuery(selector);
        var timers = [];
        function cb(data) {
            if (!data.token)
                return;
            function remove(token) { jQuery('#'+id+'_'+token+'_line').remove(); }
            function newLine(token, state, full_number, sec) {
                modified();
//                var html = '<div id="'+id+'_'+token+'_line"><span id="'+id+'_'+token+'_spinner"><img src="/v1/c/img/arrows_spinner.gif" alt="" /></span>\
//<span id="'+id+'_'+token+'_status"></span><button id="'+id+'_'+token+'_hup">Cancel</button></div><div style="clear:both;"></div>';
                var html = '<div id="'+id+'_'+token+'_line">\
<button id="'+id+'_'+token+'_hup" title="Hangup"><i class="icon icon-remove-sign" stle="color: red;"></i></button>\
<button disabled><span id="'+id+'_'+token+'_status"></span></button>\
</div>';
                d.append(html);
                var l = d.find('#'+id+'_'+token+'_line');
                l.find('button').button();
                l.find('.ui-button-text').css({'padding-left': '4px', 'padding-right': '4px'}); /* make it a bit more compact */
                //d.find('#'+id+'_'+token+'_hup').button({icons: {primary: "ui-icon-close"}, text: false}).click(function(){BRCommands.fsHup(token);});
                d.find('#'+id+'_'+token+'_hup')
                    .click(function(){BRCommands.fsHup(token);})
                    .removeClass('ui-corner-all')
                    .addClass('ui-corner-left')
                    .css('margin-right','0')
                    .next()
                    .removeClass('ui-corner-all')
                    //.addClass('ui-corner-right ui-state-active')
                    .addClass('ui-corner-right')
                    .css('opacity', '.75')
                    .css('margin-left','0')
                    ;
                //text(state + ' <b>' + full_number + '</b> (' + (sec) + ')',token);   // not very DRY
                text(state + ' ' + full_number + ' <b>' + (sec) + '</b>',token);   // not very DRY
                timers[token] = setInterval(function() {
                    //text(state + ' <b>' + full_number + '</b> (' + (--sec) + ')',token);
                    text(state + ' ' + full_number + ' <b>' + (--sec) + '</b>',token);
                    if (sec<=0 && timers[token]) {
                        clearInterval(timers[token]);
                        timers[token]=null;
                        remove(token);
                        }
                    }, 1000);
                }
            function clearLine(token,linger) {
                if (timers[token]) {
                    clearInterval(timers[token]);
                    timers[token] = null;
                    }
                jQuery('#'+id+'_'+token+'_spinner').html('');
                if (linger) setTimeout(function() { remove(token); }, linger );
                else remove(token);
                }
            switch(data.state) {
                case 'dialing':
                    newLine(data.token, 'Dial', data.full_number, data.timeout_seconds || 30);
                    break;
                case 'calling': 
                    clearLine(data.token, 0);
                    newLine(data.token, 'Ring', data.full_number, data.timeout_seconds || 30);
                    break;
                case 'connected':
                    text('<b>Connected</b>',data.token,'lime'/*'#c4e913'*/);
                    clearLine(data.token, 500);
                    break;
                case 'cancelled':
                    text('<b>Cancelled</b>',data.token,'red'/*'#e77471'*/);
                    clearLine(data.token, 500);
                    break;
                }
            }
        BRDashboard.subscribe(cb,'dialer');
    },

    breakoutGroups: function(id,selector) {
        var $j = jQuery;
        $j(selector).find('button').button();
        //$j('#'+id+'_move_button').click(function(){BRCommands.moveToRoom('delete-me', $j('#'+id+'_move option:selected').val());});
        $j('#'+id+'_move_button').click(function(){BRCommands.moveToRoom('delete-me', $(id+'_move'));});    // passing the field instead of value -- old, fix it
        //$j('#'+id+'_break_button').click(function(){BRCommands.breakOut('delete-me', $j('#'+id+'_break option:selected').val());});
        $j('#'+id+'_break_button').click(function(){BRCommands.breakOut('delete-me', $(id+'_break'));});    // passing the field instead of value -- old, fix it
        $j('#'+id+'_return_button').click(function(){BRCommands.dissolveRooms('delete-me');})
        BRWidgets.styleSelect($j('#'+id+'_move'));
        BRWidgets.styleSelect($j('#'+id+'_break'));
        function disenable(count) {
            if (count>0) {
                $j('#'+id+'_move_button').button("enable");
                BRWidgets.enableSelect($j('#'+id+'_move'),true);
                }
            else {
                $j('#'+id+'_move_button').button("disable");
                BRWidgets.enableSelect($j('#'+id+'_move'),false);
                }
            if (count>1) {
                $j('#'+id+'_break_button').button("enable");
                BRWidgets.enableSelect($j('#'+id+'_break'),true);
                }
            else {
                $j('#'+id+'_break_button').button("disable");
                BRWidgets.enableSelect($j('#'+id+'_break'),false);
                }
            }
        function select(data){disenable(BRWidgets.commonSelectedHandler(id+'_selected',data));};
        BRDashboard.subscribe(select,'select_listener');
        select({});
    },

    dialpad: function(id,selector) {
        var $j = jQuery
            , kp = $j('#'+id+'_keypad',selector)
            , ip = kp.find('input[name="number"]')
            ;
        function dial() {
            var num = '+'+ip.val();
            BR.api.v1.addParticipant(BRUtils.conferencePath(), {name: num}, function(e,d){
//console.log(e,d);
                if (e || !d || !d.user || !d.user.id || !d.user.name)
                    return alert(e || 'Error creating user for dialout');
                var token = BRUtils.makeDialToken(), to = 20;
                BRDashboard.fire({type:'dialer',state:'dialing',full_number:num,token:token,timeout_seconds:to});
                BRUtils.waitForPin(d.user.id, token, to * 1000, function(pin){
//console.log(pin);
                    if (pin) 
                        BRCommands.fsDialout(pin, num, d.user.name, token);
                    });
                });
            }
        function dtmf(c) {
            BRCommands.gue('dtmf',c);
            }
        function valid(c) { return /^[\d#\*]$/.exec(c)!==null; }
        kp.find('button').button().click(function(e){
            var c = $j(this).val();
            switch(c) {
                case 'T': dial(); break;
                case 'D': dtmf(null); ip.val(ip.val().substr(0,ip.val().length-1)); break;
                case 'C': dtmf(null); ip.val('1'); break;
                default:
                    ip.val(ip.val()+c);
                    dtmf(c);
                }
            });
        ip.keypress(function(e){
            var c = String.fromCharCode(e.charCode);
            if (!valid(c))
                return false;
            /* dtmf(c); -- think it's better leave DTMF associated with the action of clicking a button only */
            return true;
            })
/*
        .keydown(function(e){
//console.log(e);
            if (e.which===8 /*Del*./ || e.which===46 /*Backspace*./) {
                bksp();
                return false;
                }
            })
*/
        //.bind("input paste propertychange", function(e){
        .bind("paste", function(e){
            /* notes:
                - just purge out non acceptable chars, forget DTMF
                - also don't worry about caret position
            */
            setTimeout(function(){
                var o = ip.val(), n='';
                for(var i=0; i<o.length; i++)
                    if (valid(o.charAt(i)))
                        n += o.charAt(i);
                ip.val(n);
                }, 0);
            });
        BRWidgets.dialerMonitor(selector,'#call_monitor');
        function updateDialpadAccess() {
            var verb = "disable", json = null;
            if (BR.room.context.is_host) {
                verb = "enable";
                }
            else {
                json = BRDashboard.conference_access_config;
                if (json && json.participants_can_call)
                    verb = "enable";
                }
            $j('#'+id+'_talk').button(verb);
            }
        BRDashboard.subscribe(function(o) {
            if (o.idx!==/*intentional*/BR.room.context.conference_id || o.attr!=="access_config")
                return;
            updateDialpadAccess();
            }, 'conferences');
        BRDashboard.subscribe(updateDialpadAccess, 'room_context');
        updateDialpadAccess();
    },

    controls: function(id,selector) {
        var $j = jQuery;
        $j(selector).find('button').button();
        $j('#'+id+'_volume_in').slider({
            min: -4,
            max: 4,
            step: 1,
            slide: function(event, ui) {
                BRCommands.conferenceSelectedAction('volume_in '+ui.value);
                $j('#'+id+'_volume_in_level').val(ui.value);
                $j('#'+id+'_volume_in_level_text').text($j('#'+id+'_volume_in_level option:selected').text());
                }
            });
        $j('#'+id+'_volume_in_level').change(function(){
            var level = $j('#'+id+'_volume_in_level').val();
            BRCommands.conferenceSelectedAction('volume_in '+level);
            $j('#'+id+'_volume_in').slider("value",level);
            });
        function end_call() {
/*
problems getting this to center correctly
            var d = $j('#'+id+'_confirm').dialog({
                        resizable: false,
                        height:140,
                        modal: true,
                        autoOpen: false,
                        buttons: {
                            "Yes, end the call now": function() {
                                $j( this ).dialog( "close" );
                            },
                            Cancel: function() {
                                $j( this ).dialog( "close" );
                            }
                        }
                });
            d.dialog('open','position','center');
*/
            if (confirm("The conference will end and all callers will be disconnected. Press OK to confirm.")) {
                BRCommands.conferenceAction('hup all');
                }
            }
        $j('#'+id+'_mute').button("option", "label", '<i class="pull-left icon2-mic-off"></i> Mute').click(function(){BRCommands.conferenceSelectedAction('mute');})
//        $j('#'+id+'_mute').button("option", "icons", {primary:'ui-icon-volume-off'}).click(function(){BRCommands.conferenceSelectedAction('mute');})
        $j('#'+id+'_unmute').button("option", "label", '<i class="pull-left icon2-mic"></i> Unmute').click(function(){BRCommands.conferenceSelectedAction('unmute');})
//        $j('#'+id+'_unmute').button("option", "icons", {primary:'ui-icon-volume-on'}).click(function(){BRCommands.conferenceSelectedAction('unmute');})
        $j('#'+id+'_pa').click(function(){BRCommands.conferenceSelectedAction('pa');})
        $j('#'+id+'_unpa').click(function(){BRCommands.conferenceSelectedAction('unpa');})
        $j('#'+id+'_drop').button("option", "icons", {primary:'ui-icon-cancel'}).click(function(){BRCommands.conferenceSelectedAction('hup');})
        $j('#'+id+'_lock').button("option", "icons", {primary:'ui-icon-locked'}).click(function(){BRCommands.conferenceAction('lock');});
        $j('#'+id+'_unlock').button("option", "icons", {primary:'ui-icon-unlocked'}).click(function(){BRCommands.conferenceAction('unlock');}).css('display','none');
        $j('#'+id+'_start_recording').button("option", "icons", {primary:'ui-icon-play'}).click(function(){BRCommands.conferenceAction('record');}).css('display','none');
        $j('#'+id+'_stop_recording').button("option", "icons", {primary:'ui-icon-stop'}).click(function(){BRCommands.conferenceAction('norecord all');});
        //$j('#'+id+'_end_call').button("option", "icons", {primary:'ui-icon-power'}).click(function(){BRCommands.conferenceAction('hup all');});
        $j('#'+id+'_end_call').button("option", "icons", {primary:'ui-icon-power'}).click(end_call);
        function disenable(enable) {
            var disen = (enable ? "enable" : "disable");
            var p = $j('#'+id+'_selected').parent();
            p.find('button').button(disen);
            $j('#'+id+'_volume_in').slider(disen);
/*
I'm thinking this is really old
if needed use the enableSelect() instead
            if (enable)
                p.find('select').removeAttr('disabled');
            else
                p.find('select').attr('disabled',true);
*/
            }
        function select(data){disenable(BRWidgets.commonSelectedHandler(id+'_selected',data)>0);};
        BRDashboard.subscribe(select,'select_listener');
        BRDashboard.subscribe(function(o){
            if (o.on_if_defined==undefined) {
                $j('#'+id+'_lock').css('display','block');
                $j('#'+id+'_unlock').css('display','none');
                }
            else {
                $j('#'+id+'_lock').css('display','none');
                $j('#'+id+'_unlock').css('display','block');
                }
            },'lock');
        BRDashboard.subscribe(function(o){
            if (o.on_if_defined==undefined) {
                $j('#'+id+'_recording').text('Not recording');
                $j('#'+id+'_start_recording').css('display','block');
                $j('#'+id+'_stop_recording').css('display','none');
                }
            else {
                $j('#'+id+'_recording').text('Recording');
                $j('#'+id+'_start_recording').css('display','none');
                $j('#'+id+'_stop_recording').css('display','block');
                }
            },'recording');
        select({});
    },

    polling_depreciated: function(id,selector) {
        var $j = jQuery;
        function modified() { BRWidgets._modified($j(selector).prev().data('key',id+'_polling')); }
        function clear() {
            var len = BRDashboard.listeners.length;
            for(var i=0; i<len; i++) {
                BRDashboard.fire({type:'listener',command:'attr',mid:BRDashboard.listeners[i],attrs:{poll:''}});
                }
            }
        $j('#'+id+'_clear_button').button({icons:{primary:'ui-icon-cancel'}}).click(clear);
        function update() {
            /* modified(); -- skip for now -- because every listener event triggers this ... */
            var votes = {};
            function inc(idx) {
                if (votes[idx]) votes[idx]++;
                else votes[idx] = 1;
                }
            function cell(key,idx,value) {
                var elem = $j('#'+id+'_'+key+'_'+idx);
                var old_value = elem.text();
                if (value==old_value) 
                    return;
//                elem.addClass('bold-text'); this was to make modifications flash bold briefly
                elem.text(value);
//                setTimeout(function(){elem.removeClass('bold-text');},500); but overkill and makes it too busy
                }
            for(var i in BRDashboard.listener_data) {
                var l = BRDashboard.listener_data[i];
                var v = parseInt(l.poll, 10);
                if (isNaN(v)) v = 0;
                if (v>0 && v<10) {
                    inc(v);
                    inc(10);
                    }
                else {
                    inc(0);
                    }
                }
            var no_vote = votes[0] ? votes[0] : 0;
            var voted = votes[10] ? votes[10] : 0;
            var total = (no_vote+voted);
            for(var i=0; i<11; i++){
                if (votes[i]) {
                    if (i>0 && i<10 && !$j('#'+id+'_t_'+i).hasClass('bold-text'))
                        $j('#'+id+'_t_'+i).addClass('bold-text');
                    cell('c',i,votes[i]);
                    cell('p',i,Math.round((votes[i]*100)/total) + '%' );
                    if (voted && i/* don't count for 'no votes' */)
                        cell('v',i,Math.round((votes[i]*100)/voted) + '%' );
                    else
                        cell('v',i,'');
                    }
                else {
                    if ($j('#'+id+'_t_'+i).hasClass('bold-text'))
                        $j('#'+id+'_t_'+i).removeClass('bold-text');
                    cell('c',i,'');
                    cell('p',i,'');
                    cell('v',i,'');
                    }
                }
            }
        BRDashboard.subscribe(update,'listener');
        clear();
    },

    polling: function(id,selector) {
        var $j = jQuery
            , distinct_voters = {}
            , ballot_boxes = {}
            , changed = {};
            ;

        $j('#'+id+'_clear_button').button({icons:{primary:'ui-icon-cancel'}}).click(clear);

        function modified() { BRWidgets._modified($j(selector).prev().data('key',id+'_polling')); }
        function clear() {
/* this is one way to clear */
            changed = {};
            for(var v in distinct_voters)
                if (distinct_voters.hasOwnProperty(v)) {
                    dtmf(distinct_voters[v], (distinct_voters[v]=0));
                    }
/* and this is the other .... I guess leave them both available to cross check the logic? *./
            var count = 0;
            for(var v in distinct_voters)
                if (distinct_voters.hasOwnProperty(v)) {
                    count++;
                    distinct_voters[v]=0;
                    }
            for(var i=0; i<10; i++) 
                changed[i] = true;
            ballot_boxes = {0: count};
*/

            recalculate();
            }
       function cell(key,idx,value) { $j('#'+id+'_'+key+'_'+idx).text(value); }
//       function cell(key,idx,value) { $j('#'+id+'_'+key+'_'+idx).text(value); console.log(id,key,idx,value); }
       function vote(idx, adjust) {
            ballot_boxes[idx] = (ballot_boxes[idx] || 0) + adjust;
            }
        function dtmf(old_code, new_code) {
//console.log(3,old_code,new_code);
            if (old_code===new_code)
                return;
//if (typeof(old_code)!=="number") console.log('HEEEEEEEEEEEEEEEEEEEEEEELLLLL');
//if (typeof(new_code)!=="number") console.log('AAAAAAAAAAAAAAAHEEEEEEEEEEEEEEEEEEEEEEELLLLL');
            changed[old_code] = changed[new_code] = true;
            function process(v, adjust) {
//if (typeof(v)!=="number") console.log('HEEEEEEEEEEEEEEEEEEEEEEELLLLL');
                if (v>0 && v<10) {
                    vote(v, adjust);
                    vote(10, adjust);
                    }
                else
                    vote(0, adjust);
                }
            process(old_code, -1);
            process(new_code, 1);
            }
/*
        function addVoter(id, code) {
            dtmf(0, code);
            distinct_voters[id] = code;
            }
*/
        function update(id, code) {
            dtmf(distinct_voters[id] || 0, code);
            distinct_voters[id] = code;
            }
        function removeVoter(id) {
            dtmf(distinct_voters[id], 0);
            delete distinct_voters[id];
            vote(0, -1);
            }
        function recalculate() {
            var no_vote = ballot_boxes[0] || 0;
            var voted = ballot_boxes[10] || 0;
            var total = (no_vote+voted);
            var have_rows = false;
            function doRow(i) {
                if (ballot_boxes[i]) {
                    if (i>0 && i<10 && !$j('#'+id+'_t_'+i).hasClass('bold-text'))
                        $j('#'+id+'_t_'+i).addClass('bold-text');
                    cell('c',i,ballot_boxes[i]);
                    cell('p',i,Math.round((ballot_boxes[i]*100)/total) + '%' );
                    if (voted && i/* don't count for 'no votes' */)
                        cell('v',i,Math.round((ballot_boxes[i]*100)/voted) + '%' );
                    else
                        cell('v',i,'');
                    }
                else {
                    if ($j('#'+id+'_t_'+i).hasClass('bold-text'))
                        $j('#'+id+'_t_'+i).removeClass('bold-text');
                    cell('c',i,'');
                    cell('p',i,'');
                    cell('v',i,'');
                    }
                }
            for(var c in changed)
                if (changed.hasOwnProperty(c))
                    (have_rows = true) && doRow(parseInt(c) || 0/* js in is evil */);
            if (have_rows)
                doRow(10);
            cell('c',11,total);
            }
        BRDashboard.subscribe(function(o){
            changed = {};
            switch(o.command) {
                case 'show':
//console.log(1,o.data.user_id);
                    if (typeof(o.data.user_id)!=="undefined") {
                        distinct_voters[o.data.user_id] = 0;
                        vote(0, 1);
                        }
                    /* intentionally fall thru */
                case 'update':
                    if ((typeof(o.data.user_id)!=="undefined") && (typeof(distinct_voters[o.data.user_id])!=="undefined")) {
                        update(o.data.user_id, parseInt(o.data.dtmf) || 0);
                        }
                    break;
                case 'hide':
//console.log(2,o.data.user_id);
                    removeVoter(o.data.user_id); break;
                }
            recalculate();
            },'box');
        clear();
    },

    systemControls: function(id,selector) {
        var $j = jQuery;
        //$j(selector).find('button').button();
        $j(selector).find('button').first().button({icons:{primary: 'ui-icon-radio-off'}}).next().button({icons:{primary:'ui-icon-radio-on'}});
        $j('#'+id+'_deaf').click(function(){BRCommands.conferenceSelectedAction('deaf');})
        $j('#'+id+'_undeaf').click(function(){BRCommands.conferenceSelectedAction('undeaf');})
        $j('#'+id+'_volume_out').slider({
            min: -4,
            max: 4,
            step: 1,
            slide: function(event, ui) {
                BRCommands.conferenceSelectedAction('volume_out '+ui.value);
                $j('#'+id+'_volume_out_level').text(ui.value);
                }
            });
        $j('#'+id+'_volume_en').slider({
            value: 300,
            min: 0,
            max: 600,
            step: 100,
            slide: function(event, ui) {
                BRCommands.conferenceSelectedAction('energy '+ui.value);
                $j('#'+id+'_volume_en_level').text(ui.value);
                }
            });
        function disenable(enable) {
            var disen = (enable ? "enable" : "disable");
            var p = $j('#'+id+'_selected').parent();
            p.find('button').button(enable ? "enable" : "disable");
            $j('#'+id+'_volume_out').slider(disen);
            $j('#'+id+'_volume_en').slider(disen);
            }
        function select(data){disenable(BRWidgets.commonSelectedHandler(id+'_selected',data)>0);};
        BRDashboard.subscribe(select,'select_listener');
        select({});
    },

    chat: function(id) {
        var $j = jQuery;
        $j('body').append('<div class="chat_position"><div id="'+id+'_chat"></div></div>');
        var selector = '#' + id + '_chat';
        var chat_width = 340;
        var notify_key = id+'_chat';
        $j(selector).html('\
<div class="ui-accordion ui-widget ui-helper-reset ui-accordion-icons" style="width: '+chat_width+'px;">\
<h3 class="ui-accordion-header ui-widget-header ui-helper-reset ui-state-default ui-state-ctive ui-corner-top">\
<!--<span class="ui-icon ui-icon-person" style="position: absolute; margin-top: -3px;"></span>-->\
<span style="position: static; display: inline;">\
<i id="nk_'+notify_key+'" class="icon-star"> </i>\
<i class="icon-comments"></i>\
\ Chat</span>\
<i id="'+id+'_close" class="icon icon-resize-small pull-right"></i>\
</h3>\
<div id="'+id+'_frame" style="height: 300px; display: none; border: 1px solid #ccc; border-top: none; width: '+(chat_width-2)+'px;"></div>\
</div>\
');
        $j('#'+id+'_frame').append('<div class="ui-widget-content" id="'+id+'_content" style="font-size: 11px; height: 275px; overflow-y: scroll; border: 0;"></div>\
<input id="'+id+'_input" style="border: 0; border-top: 1px solid #ccc; background-color: #fff; padding: 0; margin: 0; margin-bottom: 1px; bottom: 0px; position: absolute; outline: 0; height: 22px; font-size: 11px; width: '+(chat_width-2)+'px" />\
');
        var content = $j('#'+id+'_content');
        function scrollToEnd() { content.prop({scrollTop: content.prop("scrollHeight")}); }
        var h3tag = $j(selector).find('h3');
        var notify_icon = $j('#nk_'+notify_key).toggle();
        $j('#'+id+'_close').hide();
        function notify_fn(flag) {
            switch(flag) {
                case 0:
                    h3tag.addClass('ui-state-highlight');
                    setTimeout(function(){ h3tag.removeClass('ui-state-highlight'); }, 100); 
                    break;
                case 1:
                    notify_icon.show();
                    break;
                case 2:
                    //h3tag.removeClass('ui-state-highlight');
                    notify_icon.hide();
                    break;
                case 3:
                    //if (h3tag.hasClass('ui-state-highlight'))
                    //h3tag.removeClass('ui-state-highlight');
                    notify_icon.hide();
                }
            }
        h3tag.click(function(e){
            //$j('#'+id+'_frame').toggle('fast'); -- not a fan of this effect anymore
            $j('#'+id+'_frame').toggle();
            $j('#'+id+'_close').toggle();
            BRDashboard.resetNotify(notify_key);
            if (content.is(":visible"))
                scrollToEnd();  /* must do this each time expanded */
            });
        var input = $j('#'+id+'_input');
        input.keydown(function(e){
            if (e.keyCode==13) BRCommands.sendChat(BR.room.context.user_id, BR.room.context.user_name, id+'_input');
            });
        var month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        BRDashboard.subscribe(function(o){
            var user_id = null, user = '', msg = o.data;
            if (msg.match(/^(\d+)-([^:]*):(.*)$/)) {
                user_id = RegExp.$1;
                user = RegExp.$2;
                msg = RegExp.$3;
                }
            else if (msg.match(/^([^:]*):(.*)$/)) {
                user = RegExp.$1;
                msg = RegExp.$2;
                }
            var avatar = null;
            if (user_id && BRDashboard.user_map && BRDashboard.user_map[user_id] && BRDashboard.user_map[user_id].avatar_small)
                avatar = BRDashboard.user_map[user_id].avatar_small;
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
            msg_top += time + '</div><div style="clear: both;"></div></div>';
            var left_width = 50;
            var sb_width = 28;
            if (avatar)
                content.append('<div style="float: left; width: '+left_width+'px;"><img src="'+avatar+'" alt="'+user+'" title="'+user+'"></div>')
            else
                content.append('<div style="float: left; width: '+left_width+'px; font-weight: bold; overflow: hidden; padding: 2px;">'+user+'</div>')
            content
                .append(
                    '<div style="float: right; width: '+(chat_width-(left_width+sb_width))+'px; padding: 0px;">'+msg_top+
                    '<div style="padding: 2px;">'+msg+'</div></div>')
                .append('<div style="clear: both; height: 20px;"></div>');
            if (!content.is(":visible"))
                BRDashboard.notify(notify_key, notify_fn);
            //if (!content.is(":visible") && !h3tag.hasClass('ui-state-highlight'))
            //    h3tag.addClass('ui-state-highlight');
            scrollToEnd();
            },'chat');
        BRDashboard.subscribe(function(o){
            switch(o.command) {
                case 'clearChat':
                    content.empty();
                    break;
                }
            },'command');
        }
};

