/* this was formerly the "application.js", now purged */

var BRParticipants =  {
    lastId: 0,
//    currentSampleNb: 0,
//    arrData: new Array(),
//    chatWin: null,
//    ssWin: null,
//    partWin: null,
//    selectedParticipantCount: 0,
//    eaS: null,
    lMap: new Array,

    getNewId: function() {
        BRParticipants.lastId++;
        return "wid_" + BRParticipants.lastId;
    },

    listenerMap: function(token) {
        if (!BRParticipants.lMap[token]) {
            BRParticipants.lMap[token] = new Array;
            }
        return BRParticipants.lMap[token];
    },

    addListener: function(token,fn) {
        BRParticipants.listenerMap(token).push(fn);
    },

    notifyListeners: function(token,arg) {
        var arr = BRParticipants.listenerMap(token);
        for(var i=0; i<arr.length; i++) {
            arr[i](arg);
            }
    },

    removeListener: function(token,fn) {
        var arr = BRParticipants.listenerMap(token);
        var idx = arr.indexOf(fn);
        if (idx>-1)
            arr.splice(idx,1);
    },

    openParticipantWindow2: function(grid) {
        var theme = 'cs_workspace';
        var id = BRParticipants.getNewId();
        //var win = new Window(id, {
        var win = new Object(id, {
            className: theme,
//            bottom: 0,    -- either of these 2 parameters cause this
//            right: 0,     -- to lose it's constraints
            width:722,
            height:483,
            maximizable:false,
//            minimizable:false,
            closable: true,
            resizable: false,
            recenterAuto: false,
/*
            showEffect: Element.show, -- what was this?
            hideEffect: Element.hide,
*/
            title: "Participants"
            });
/*
        BRParticipants.partWin = win;
        BRParticipants.constrain(win);
*/
//        BRParticipants.selectedParticipantCount = 0;
        var notifySelectedUpdated = function() {
            BRParticipants.notifyListeners('selected_participants');
            }
        var rowSelected = function(rowid,selected) {
            var ids = grid.jqGrid('getGridParam','selarrrow');
//            BRParticipants.selectedParticipantCount = ids.length;
            notifySelectedUpdated();
            BRDashboard.fire({type:'select_listener',id:rowid,selected:selected});
            }
        var allRowsSelected = function(aRowids,selected) {
            var len = aRowids.length;
            for(var i=0; i<len; i++)
                rowSelected(aRowids[i],selected);
            }
        grid.jqGrid({
    datatype: "local",
    width: "720",
    height: 480,
    multiselect: true,
    rowNum: 100000,
    shrinkToFit: false,
    colNames:['','','Role','', 'Name', 'Number','Caller Id','Group','Poll','Notes'],
    colModel:[
        {name:'id', index:'id', width:60, hidden: true, sorttype:"int"},
        {name:'icon', index:'icon', width:32},
        {name:'role', index:'role', width:40},
        {name:'controls', index:'controls', width:16},
        {name:'name', index:'name', width:192},
        {name:'dialout', index:'dialout', width:128},
        {name:'callerid', index:'callerid', width:128},
        {name:'group', index:'group', sortype:"int", width:64},
        {name:'poll', index:'poll', width:56},
        {name:'notes', index:'notes', width:4}
    ],
//    caption: "Participants",
    pager: "#pgrid",
    viewrecords: true,
    onSelectRow: rowSelected,
    onSelectAll: allRowsSelected
});
        win.clearPolls = function() {
            var ids = grid.jqGrid('getDataIDs');
            for(var i=0; i<ids.length; i++) {
                var idx = ids[i];
                grid.jqGrid('setRowData',idx,{poll: ''});
                }
            }
        win.capture = function() {
            return grid.jqGrid('getRowData');
            }
        win.dispatchCh = 'K';
        var addFlag = function(grid,idx,flag) {
            var row = grid.jqGrid('getRowData',idx);
            if (row==undefined)
                return;
            var value = flag + row.controls.replace(flag,'');
            if (value!=row.controls) {
                grid.jqGrid('setRowData',idx,{controls: value});
                }
            };
        var removeFlag = function(grid,idx,flag) {
            var row = grid.jqGrid('getRowData',idx);
            if (row==undefined)
                return;
            var value = row.controls.replace(flag,'');
            if (value!=row.controls) {
                grid.jqGrid('setRowData',idx,{controls: value});
                }
            };
        var updateParticipantGrid = function(grid,idx,value,attr) {
//alert("attr=" + attr + ", value=" + value);
            switch(attr) {
                case undefined:
//alert("undefined attr=" + attr + ", value=" + value);
                    if (value==undefined) {
                        var selected_ids = grid.jqGrid('getGridParam','selarrrow');
                        if (selected_ids.indexOf(idx)>-1) {
//                            BRParticipants.selectedParticipantCount--;
                            notifySelectedUpdated();
                            BRDashboard.fire({type:'select_listener',id:idx,selected:false});
                            }
                        grid.jqGrid('delRowData',idx);
                        }
                    else {
//alert("ADD ROW!!!! attr=" + attr + ", value=" + value);
                        grid.jqGrid('addRowData',idx,{icon: '<img src="'+BR.api.v1.get_host('cdn')+'/v1/c/img/blank.png" />'});
                        }
                    break;
                case 'name':
                    grid.jqGrid('setCell', idx, 'name', value, 'cs-participant-active',{});
                    break;
                case 'mute':
                    if (value==undefined)
                        removeFlag(grid,idx,'M');
                    else
                        addFlag(grid,idx,'M');
                    break;
                case 'pa':
                    if (value==undefined)
                        removeFlag(grid,idx,'P');
                    else
                        addFlag(grid,idx,'P');
                    break;
                case 'deaf':
                    if (value==undefined)
                        removeFlag(grid,idx,'D');
                    else
                        addFlag(grid,idx,'D');
                    break;
                case 'dialout':
                    grid.jqGrid('setRowData',idx,{dialout: value});
                    break;
                case 'callerid':
                    grid.jqGrid('setRowData',idx,{callerid: value});
                    break;
                case 'role':
                    grid.jqGrid('setRowData',idx,{role: value});
                    break;
                case 'group':
                    if (value=='0')
                        value = '';
                    grid.jqGrid('setRowData',idx,{group: value});
                    break;
                case 'poll':
                    grid.jqGrid('setRowData',idx,{poll: value});
                    BRParticipants.notifyListeners('poll',{index:idx, value:value});
                    break;
                default:
//alert("DEFAULT!!! attr=" + attr + ", value=" + value);
                }
            };
        var updateTalking = function(grid,idx,value) {
            var speaker_table = $(id + '_speaker_table');
            var speaker_field = $(id + '_speaker');
            var row = grid.jqGrid('getRowData',idx);
            var field_str = '';
            if (row!=undefined && row.name!=undefined) {
                field_str = row.name;
                }
            if (value==undefined) {
                grid.jqGrid('setRowData',idx,{icon: '<img src="'+BR.api.v1.get_host('cdn')+'/v1/c/img/blank.png">'});
                if (speaker_field.length && speaker_field.innerHTML==field_str) {
                    speaker_field.innerHTML = '';
                    }
                if (speaker_table.length)
                    speaker_table.style.borderColor = '#fff';
                }
            else {
                grid.jqGrid('setRowData',idx,{icon: '<img src="'+BR.api.v1.get_host('cdn')+'/v1/c/img/mic-talking.png" alt="T">'});
                if (speaker_field.length) {
                    speaker_field.innerHTML = field_str;
                    }
                if (speaker_table.length) {
                    speaker_table.style.borderColor = '#9cb391';
                    }
                }
            };
        var dispatchData3 = function(key,value) {
            var sk = key.split(/-/, 3); // subkeys
            if (sk.length<2)
                return;
            var verb = sk[0];
            var idx = parseInt(sk[1], 10);
            var attr = sk[2];
            if (grid == undefined)
                return;
            switch(verb) {
                case 'member':
                updateParticipantGrid(grid,idx,value,attr);
                break;
            case 'talking':
                updateTalking(grid,idx,value);
                break;
            default:
                ;
            }
            };
        win.dispatchFn = function(str) {
            if (str.length < 1)
                return;
            var kv = str.split(/:\s*/,2);
            var value = kv[1];
            if (value==undefined && /:/.test(str)) { // for IE
                value = '';
                }
//alert("kv[0]="+kv[0]+",value="+value);
            dispatchData3(kv[0], value);
            };
        win.resetFn = function() {
            if (grid != undefined)
                grid.jqGrid('clearGridData', true);
            var speaker_table = $(id + '_speaker_table');
            if (speaker_table.length)
                speaker_table.style.borderColor = '#fff';
            var speaker_field = $(id + '_speaker');
            if (speaker_field.length)
                speaker_field.innerHTML = '';
            };
        BRDashboard.subscribe(function(data){
            win.resetFn(data.str);
            },'_R');
        BRDashboard.subscribe(function(data){
            win.dispatchFn(data.str);
            },'_K');
        function selected_fn(o) {
            var selected = (grid.jqGrid('getGridParam','selarrrow').indexOf(o.id)>-1);
            if (selected != o.selected) {
                grid.jqGrid('setSelection',o.id,false);
                var ids = grid.jqGrid('getGridParam','selarrrow');
//                BRParticipants.selectedParticipantCount = ids.length;
                }
            }
        BRDashboard.subscribe(selected_fn,'select_listener');
/*        win.setCloseCallback(function(){
            BRDashboard.unsubscribe(selected_fn);
            BRParticipants.partWin = null;
            return true;
            }); */
/*        BRParticipants.replayData(win); TODO -- can we live without this? */
        }

}

