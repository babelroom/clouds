var BRConference = {

    api_error: function(e) {
        alert("An error occured processing your request.");
    },

    statusOn: function(h,msg,button) {
        jQuery('#'+h.id+'_status').text(msg);
        var pb = jQuery('#'+h.id+'_progress');
        pb.data("cs_timer", setInterval(function(){
            var val = pb.progressbar("option", "value");
            if (val<100)
                pb.progressbar("option", "value", val+2);
            }, 20));
        pb.progressbar("option","value",20).css('display','block');
        if (button)
            button.button("disable");
    },

    statusOff: function(h,button) {
        var pb = jQuery('#'+h.id+'_progress');
        clearInterval(pb.data("cs_timer"));
        pb.progressbar("option","value",100);
        setTimeout(function(){
            pb.css('display','none');
            }, 20);
        jQuery('#'+h.id+'_status').text('');
        if (button)
            button.button("enable");
    },

    demoHostTest: function() {
        if (BR.room.context.is_host)
            return true;
        alert('This host-only feature is shown for demonstration purposeses only.\n\nOnly hosts may change conference level settings.');
        return false;
    },

    stub: function(go,fn) {
        return go?fn():undefined;
    },

    conference_settings_html: function(id) {
        var cxt = BR.room.context;
        return '\
<div id="'+id+'_tabs" style="width: 500px; border: none;">\
<ul>\
    <li><a href="#'+id+'_uri">URL</a></li>\
    <li><a href="#'+id+'_general">General</a></li>\
    <li><a href="#'+id+'_access">Access</a></li>\
    <li><a href="#'+id+'_skin">Skin</a></li>\
</ul>\
    <div id="'+id+'_uri">\
        <label>Current URL<div>\
            <span class="secure-green"><i class="icon2-lock"></i> https:</span>'+BR.api.v1.get_host('page')+'/<span style="color: #999;" id="'+id+'_current_uri"></span></div></label>\
        <br>\
        <label>Enter new URL<br><input id="'+id+'_uri_delete_me" name="conference[uri]" type="text" /><span id="'+id+'_uri_msg" class="fieldWithErrors"></span></label>\
        <div>\
            <span class="secure-green"><i class="icon2-lock"></i> https:</span>'+BR.api.v1.get_host('page')+'/<span style="color: #999;" id="'+id+'_uri_echo"></span></div>\
        <br>\
        <center><button id="'+id+'_save_uri"><i class="icon2-save pull-left"></i> &nbsp; Save</button></center>\
    </div>\
    <div id="'+id+'_general">\
        <label>Title<br><input name="conference[name]" type="text" style="width: 100%;" /></label><span id="'+id+'_name_msg"></span>\
        <br>\
        <label>Description<br><textarea name="conference[introduction]" style="width: 100%;"></textarea></label>\
        <p>\
        <center><button><i class="icon2-save pull-left"></i> &nbsp; Save</button></center>\
    </div>\
    <div id="'+id+'_access">\
        <br>\
        <center><button><i class="icon2-save pull-left"></i> &nbsp; Save</button><button><i class="icon2-ccw pull-left"></i> &nbsp; Reset</button></center>\
    </div>\
    <div id="'+id+'_skin">\
        <center><table><tr><td><button class="prev">&lt;</button></td>\
        <td><div id="'+id+'_scrollable" class="scrollable">\
            <div class="items">\
                <!-- items loaded dynamically -->\
            </div>\
        </div></td>\
        <td><button class="next">&gt;</button></td></tr></table></center>\
        <br>\
        <center><span id="'+id+'_skin_selected">Loading...</span></center><br>\
        <center><button id="'+id+'_skin_save"><i class="icon2-save pull-left"></i> &nbsp; Save</button></center>\
    </div>\
    <center><table width="80%" height="30"><tr><td width="50%"><div id="'+id+'_status" style=""></div></td><td width="50%"><div id="'+id+'_progress" style="height: 5px; display: none;"></div></td></tr></table><center>\
</div>';
    },

/*
this works really well -- but unused for now as it doesn't allow us to return a cancel/OK code
    confirm_dialog: function(id) {
        var $j = jQuery;
        $j('#'+id+'_confirm').dialog({
            resizable: false,
            height:140,
            modal: true,
            buttons: {
                Leave: function() {
                    $j( this ).dialog( "close" );
                    },
                Cancel: function() {
                    $j( this ).dialog( "close" );
                    },
                }
            });
    },
<div id="'+id+'_confirm" title="Confirm" style="display: none;">\
    <p><span class="ui-icon" style="float: left; margin: 0 7px 20px 0;"><i class="ui-widget-content icon-2x"></i></span>You have unsaved changes. Are you sure you want to leave?\
</div>\
*/
    conference_settings_logic: function(o) {
        var $j = jQuery;
        var cxt = BR.room.context;
        var h = $j.extend({
            }, o);
        $j('#'+h.id+'_tabs').tabs();
        $j(h.root).find('button').button({disabled: true});
        $j('#'+h.id+'_progress').progressbar({value: 0});

        /* URI */
        //function to_uri(u) { return u ? u : ('byid/'+cxt.conference_id); }
        function to_uri(u) { return u ? u : ('i/'+cxt.conference_id); }
        function set_current_uri() { $j('#'+h.id+'_current_uri').text(to_uri(cxt.conference_uri)); }
        set_current_uri();
//        var f_uri = $j('#'+h.id+'_uri');
        var f_uri = $j(h.root).find('input[name="conference\\[uri\\]"]');
        f_uri.val(cxt.conference_uri);
        var f_save_uri = $j('#'+h.id+'_uri').find("button:first");
        function uri_error(msg) {
            $j('#'+h.id+'_uri_msg').text(msg);
            $j('#'+h.id+'_uri').find("input"/*,label"*/).addClass('fieldWithErrors');
            }
        f_uri.keyup(function(){
            $j('#'+h.id+'_uri_echo').text(to_uri(f_uri.val()));
            f_save_uri.button("enable");
            $j('#'+h.id+'_uri_msg').text('');
            $j('#'+h.id+'_uri').find("input"/*,label"*/).removeClass('fieldWithErrors');
            });
        f_uri.keyup();
        function save_uri() {
            BRConference.statusOn(h,'Saving...');
            var new_uri = f_uri.val();
            BRUtils.aq(11, {f:{uri:new_uri},id:cxt.conference_id}, function (data, textStatus) {
                BRConference.statusOff(h);
                if (textStatus=='success') {
                    BRConference.statusOn(h,'Reloading page...');
                    document.location = '/'+to_uri(new_uri);
/*
                    cxt.uri = new_uri;
                    set_current_uri();
*/
                    }
                else if (textStatus=='error') {
                    BRConference.api_error();
                    f_save_uri.button("enable");
                    }
                });
            }
        f_save_uri.click(function(){
            if (!BRConference.demoHostTest())
                return;
            f_save_uri.button("disable");
            if (f_uri.val().length<3) {
                uri_error('Invalid URL');
                return;
                }
            BRConference.statusOn(h,'Checking...');
            //BRUtils.aq(15, {ah:{uri:f_uri.val()}}, function (data, textStatus) {
            BRUtils.aq(15, {ah:[f_uri.val(),f_uri.val()] /* 'lil hack this aq thing is going away soon.. */}, function (data, textStatus) {
                BRConference.statusOff(h);
                if (textStatus=='success') {
                    var result = eval(data);
                    var exists = (result.length>0);
                    if (result!=null) {
                        if (exists) {
                            uri_error('Taken, please select another URL');
                            }
                        else {
                            save_uri();
                            }
                        }
                    }
                else {
                    f_save_uri.button("enable");
                    BRConference.api_error();
                    }
                });
            });

        /* General */
        var f_name = $j(h.root).find('input[name="conference\\[name\\]"]');
        var f_intro = $j(h.root).find('textarea[name="conference\\[introduction\\]"]');
        var f_save_general = $j('#'+h.id+'_general').find("button:first");
        f_name.val(cxt.conference_name);
        f_intro.val(cxt.conference_introduction);
        f_save_general.button('enable');
        f_save_general.click(function(){
            if (!BRConference.demoHostTest())
                return;
            BRConference.statusOn(h,'Saving...');
            BRUtils.aq(11, {f:{name:f_name.val(),introduction:f_intro.val()},id:cxt.conference_id}, function (data, textStatus) {
                BRConference.statusOff(h);
                if (textStatus=='success') {
                    /* don't do this here anymore ... BRConference.statusOn(h,'Reloading page...');
                    document.location.reload(true); */
                    cxt.conference_name=f_name.val();
                    cxt.conference_introduction=f_intro.val();
                    }
                else if (textStatus=='error') {
                    BRConference.api_error();
                    }
                });
            });

        /* Access */
        var access_sel = '#'+h.id+'_access';
        var f_save_access = $j(access_sel).find("button:first");
        var f_save_reset = f_save_access.next('button');
        var access_tree = o.access_tree;
        var access_tree_orig_data = null;
        BRDynamic.addLogic(o.access_tree);
        BR.api.v1.conferences(cxt.conference_id, function(e,conf){
//console.log(BR.room);
            if (e) return;
            try { access_tree_orig_data=jQuery.parseJSON(conf.access_config||'{}'); }
            catch(err) {console.log(err);}
            if (access_tree_orig_data===null)
                access_tree_orig_data = {};
            BRDynamic.set(o.access_tree, access_tree_orig_data);
            function canLeave() {
                /* result = BRConference.confirm_dialog(h.id); -- don't use for now as it doesn't allow us to cancel action (though it is pretty) */
                /* returning false cancels action, i.e. can't leave */
                return !BRDynamic.modified(o.access_tree) || confirm("You have unsaved changes. Are you sure you want to leave?");
                }
            $j('#'+h.id+'_tabs').on("tabsbeforeactivate", function(e,u) {
                /* not fired when dialog is closing */
                if (u.oldPanel && u.newPanel && u.oldPanel.selector===access_sel && u.newPanel.selector!==access_sel)
                    return canLeave() && (/* reset */BRDynamic.set(o.access_tree, access_tree_orig_data) || true);
                })
            BRConference.statusOff(h,f_save_access);
            f_save_reset.button('enable').click(function(){
                BRDynamic.set(o.access_tree, access_tree_orig_data);
                });
            f_save_access.click(function(){
                var changed = BRDynamic.get(o.access_tree);
                var new_data = {};
                jQuery.extend(new_data, access_tree_orig_data, changed);
//console.log('new_data',changed);
                conf.access_config = JSON.stringify(new_data);
                BRConference.statusOn(h,'Saving...',f_save_access);
//console.log('conf',conf);
                BR.api.v1.update(conf, function(e,d){
                    BRConference.statusOff(h,f_save_access);
                    if (e) {
                        BRConference.api_error(e);
                        return;
                        }
                    access_tree_orig_data = new_data;
                    BRDynamic.set(o.access_tree, access_tree_orig_data);
                    }) || BRConference.statusOff(h,f_save_access);
                });
            });
/*
        var access_obj = $j.parseJSON(cxt.conference_access_config);
        var f_public = $j('#'+h.id+'_access_public_yes');
        if (access_obj) {
            if (access_obj.public)
                f_public.attr('checked',true);
            }
        $j('#'+h.id+'_access_public').buttonset();
        var f_save_access = $j('#'+h.id+'_access').find("button:first");
        f_save_access.click(function(){
            if (!BRConference.demoHostTest())
                return;
            BRConference.statusOn(h,'Saving...');
            var access_config = "{";
            if (f_public.attr('checked'))
                access_config += '"public": "yes",';
            access_config += '"last": "entry"}';
            BRUtils.aq(11, {f:{access_config:access_config},id:cxt.conference_id}, function (data, textStatus) {
                BRConference.statusOff(h);
                if (textStatus=='success') {
                    cxt.conference_access_config = access_config;
                    /* no need to reload, maybe later when we push out an msg BRConference.statusOn(h,'Reloading page...');
                    document.location.reload(true); *./
                    }
                else if (textStatus=='error') {
                    BRConference.api_error();
                    }
                });
            });
*/

        /* Skin */
        var skin = $j('#'+h.id+'_skin');
        var selected_skin_id = cxt.conference_skin_id;
        skin.find("button.prev").button({icons: {primary: "ui-icon-seek-prev"}, text: false});
        skin.find("button.next").button({icons: {primary: "ui-icon-seek-next"}, text: false});
        BRUtils.aq(7, {ah:[]}, function (data, textStatus) {
            var skin_selected = $j('#'+h.id+'_skin_selected');
            if (textStatus=='success') {
                skin_selected.text('Unavailable');
                var skins = eval(data);
                var html = '<div>';
                var j = 0;
                for(var i=0; i<skins.length; i++) {
                    var sk = skins[i].skin;
                    if (sk.preview_url && sk.preview_url.length>0) {
                        html += '<img src="'+sk.preview_url+'" alt="'+sk.id+':'+sk.name+'" />';
                        if (j && (!(j % 3)) && ((skins.length-j)>1))
                            html += '</div><div>';
                        j++;
                        }
                    }
//return; /* I believe I removed flowplayer tools, hence the following gives an error.. TODO tmp. */
                skin.find(".items:first").append(html+'</div>');
                $j('#'+h.id+'_scrollable').scrollable();
                skin.find(".items img").click(function(){
                    if ($j(this).hasClass("active"))
                        return;
                    skin.find(".items img").removeClass("active");
                    if ($j(this).addClass("active").attr('alt').match(/^(\d+):(.*)$/)) {
                        var id = RegExp.$1;
                        var name = RegExp.$2;
                        if (selected_skin_id!=id)
                            f_save_skin.button("enable");
                        selected_skin_id = id;
                        skin_selected.text(name);
                        }
                    });
                skin.find('img[alt^="'+cxt.conference_skin_id+':"]').click();
                }
            else if (textStatus=='error') {
                BRConference.api_error();
                skin_selected.text('Failed to load skin selection');
                }
            });

        var f_save_skin = $j('#'+h.id+'_skin_save');
        f_save_skin.click(function(){
            if (!BRConference.demoHostTest())
                return;
            BRConference.statusOn(h,'Saving...');
            BRUtils.aq(11, {f:{skin_id:selected_skin_id},id:cxt.conference_id}, function (data, textStatus) {
                BRConference.statusOff(h);
                if (textStatus=='success') {
                    BRConference.statusOn(h,'Reloading page...');
                    document.location.reload(true);
                    }
                else if (textStatus=='error') {
                    BRConference.api_error();
                    }
                });
            });

    }

}

