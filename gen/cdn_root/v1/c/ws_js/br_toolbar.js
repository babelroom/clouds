var BRToolbar = {
    qs_dict: null,

    _doorAction: function(){},   /* re-assigned later by door */

    _getQueryString: function() {
        if (BRToolbar.qs_dict)
            return BRToolbar.qs_dict;
        var qs = window.location.search;
        var dict   = {},
            match,
            pl     = /\+/g,  // Regex for replacing addition symbol with a space
            search = /([^&=]+)=?([^&]*)/g,
            decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); };
        while (match = search.exec(qs.substring(1)))
            dict[decode(match[1])] = decode(match[2]);
        BRToolbar.qs_dict = dict;
        return dict;
        },
    
    _frankenURL: function(opts) {
        opts = opts || {};
        function yo(o) { return typeof(opts[o])==="undefined" ? window.location[o] : (opts[o]||''); } 
        return yo('protocol') + '//' +yo('hostname') + yo('pathname') + yo('search');
        },

    login_token: function() {
        var dict = BRToolbar._getQueryString();
        return dict.t ? dict.t : null;
        },

    login_by_token: function(fnerror) {
        var dict = BRToolbar._getQueryString();
        var success_url = BRToolbar._frankenURL({search:null});  /* drop query string */
        BR.api.v1.login({token: dict.t}, {success_url:success_url, fnerror:fnerror});
        },

    setup: function() {
        var $j = jQuery;
        /* --- menu and it's button -- */
        var menu = $j('#menu').menu().hide();
        var menu_button = $j('#menu_button');
        menu_button.find('span:first').css({overflow: 'hidden', 'white-space': 'nowrap', width: '64px'});
        menuOn = function() {
//            menu.show();
            menu.show().position({
                my: "left top",
                at: "left bottom",
                //of: this,
                of: '#menu_button'
                //offset: "50, 100"  -- because it doesn't seem to be working ...
                });
            }
        menuOff = function() { menu.hide(); }
        menu.mouseover(menuOn).mouseout(menuOff);
        menu_button.mouseover(menuOn).mouseout(menuOff);
        menu_button.bind('dblclick',function(e) {   /* don't leave this + click in at same time: http://api.jquery.com/bind/ */
            if (e.clientX>15 || e.altKey || !e.shiftKey || !e.ctrlKey) 
                return;
            BRDashboard.updateRoomContext('is_host',!BR.room.context.is_host);
            function easter(on) {   /* actually change the css rule for current elements in the DOM *and elements created in the future* */
                for(var s = 0; s < document.styleSheets.length; s++) {
                    var ss = document.styleSheets[s];
                    var rules = ss.cssRules || ss.rules;
                    var h1Rule = null;
                    for (var i = 0; i < rules.length; i++) {
                        var rule = rules[i];
                        //if (/(^|,) *h1 *(,|$)/i.test(rule.selectorText)) {    -- example
                        if (/^.br-easter$/i.test(rule.selectorText)) {
                            if (on) rule.style.visibility = 'visible';
                            else rule.style.visibility = 'hidden';
                            return;
                            }
                        }
                    }
                }
            easter(BR.room.context.is_host);
            });

        var my_user_id = null;
        var my_invitee_id = null;
//        var my_role = 'undetermined';
        var my_label = null;
        function contextUpdated(o) {
            if (!o || o.updated.is_host) {
                if (BR.room.context.is_host) {
                    //$j('.participant_only').css({'display': 'none'});
                    $j('.participant-only').hide();
                    $j('.host-only').show();
                    menu.find('.host-only-menuitem').removeClass('ui-state-disabled');
                    }
                else {
                    $j('.participant-only').show();
                    $j('.host-only').hide();
                    menu.find('.host-only-menuitem').addClass('ui-state-disabled');
                    }
                }
            if (!o || o.updated.email_address) {
                if (BR.room.context.email_address) menu.find('.non-ephemeral-only-menuitem').removeClass('ui-state-disabled');
                else menu.find('.non-ephemeral-only-menuitem').addClass('ui-state-disabled');
                }
            updateLabel();
            }
        function updateLabel() {
            var new_label = '<i class="'+(BR.room.context.is_host?'icon-magic':'icon-user')+' pull-left"></i>';
            new_label += (my_user_id && BRWidgets.full_name(my_user_id)) || 'Loading...';
            if (my_label!==new_label) {
                my_label = new_label;
                menu_button.button('option','label',my_label);
                }
            }
        BRDashboard.subscribe(function(o){
            /* depreciate soon so we can yank data.connection_id from box TODO tmp */
//            if (o.data && o.data.connection_id && o.data.connection_id==/*deliberate==*/BRDashboard.connection_id) {
            if (o.data && BRDashboard.connection_id && (BRDashboard.connection_id in o.data.connection_ids)) {
                /* this might be a little too complex ... tmp TODO
                consider: BR.room.context.invitation_id, BR.room.context.user_id */
                if (!my_user_id && o.data.user_id) my_user_id = o.data.user_id;
                if (!my_invitee_id && o.data.invitee_id) my_invitee_id = o.data.invitee_id;
                updateLabel();
                }
            },'box');
//        BRDashboard.subscribe(function(o){ if (my_invitee_id && o.data && o.data.id===my_invitee_id) checkLabel(); }, 'invitee'); -- box might be all we need ...
//console.log(BR.room.context.is_host);
        BRDashboard.subscribe(contextUpdated, 'room_context');
        contextUpdated(null);     /* setup once to initial value */
    },

    menuAction: function(item) {
        var $j = jQuery;
        function make_webcall_url() {
            var url = BR.api.v1.get_host('cdn')+'/cdn/v1/c/flash/flash.html?url='+encodeURIComponent('rtmp:'+BR.api.v1.get_host('live')+'/phone')+'&pin='+BR.room.context.pin;
            return url;
            }
        $j('#menu').hide();
        switch(item) {
            case 'a':
                BROverlays.connect({webcall_url: make_webcall_url()});
                break;
            case 'b':
                if (!BR.room.context.is_host) return false;
                BROverlays.guests();
                break;
            case 'c':
                if (!BR.room.context.email_address) return false;
                window.open(BR.api.v1.get_host('my'), '_blank');
                break;
            case 'd':
                if (!BR.room.context.is_host) return false;
                BROverlays.conference_settings();
                break;
            case 'e':
                if (!BR.room.context.is_host) return false;
                BRToolbar.resetDialog();
                break;
            case 'f':
                BR.api.v1.logout();
                break;
            }
        return false;
    },

    pageReload: function() {
        (window.location.reload && window.location.reload(false)) ||                        /* new */
            (window.location.href = window.location.pathname + window.location.search);     /* old */
    },

    resetDialog: function() {
        BROverlays.generic({
            id: BRWidgets.nextId(),
            title: 'Reset Room',
            content: function(id) {
                return '\
<div class="ui-widget"><div id="'+id+'_error" class="ui-state-error ui-corner-all" style="display: none; padding 0 .7em; margin: 10px 0 15px 0;"></div></div>\
<div id="'+id+'_content">\
    <input id="'+id+'_cb_chat" type="checkbox" checked /><label for="'+id+'_cb_chat"> Clear chat messages</label><br>\
    <input id="'+id+'_cb_slides" type="checkbox" checked /><label for="'+id+'_cb_chat"> Clear slides</label><br>\
    <input id="'+id+'_cb_call" type="checkbox" checked /><label for="'+id+'_cb_chat"> Clear listeners. This will end any active call</label><br>\
    <input id="'+id+'_cb_online" type="checkbox" checked /><label for="'+id+'_cb_chat"> Clear online users. This will cause all connected devices to refresh</label><br>\
    <span class="br-easter"><input id="'+id+'_cb_oldusers" type="checkbox" /><label for="'+id+'_cb_chat"> Turbo purge. Clear disconnected ephemeral users. This option should be used with great care</label><br></span>\
    <div style="height: 20px;"></div>\
    <div style="text-align: center;">\
        <button id="'+id+'_btn_close" title="Cancel"><i class="icon icon-remove"></i> &nbsp;Cancel</button>\
        <button id="'+id+'_btn_reset" title="Refresh"><i class="icon icon-refresh"></i> &nbsp;Reset Room</button>\
    </div>\
</div>\
';
                },
            logic: function(id,selector) {
//                console.log(id,selector);
                var dlg = jQuery(selector), pdlg = dlg.parent();
                pdlg.find(':button').button();
                function e(name) { return jQuery('#'+id+name,pdlg); }
                e('_btn_close').click(function(){dlg.dialog('close');});
                e('_btn_reset').click(function(){
                    if (e('_cb_chat').prop('checked'))
                        BRCommands.commandAction('clearChat');
                    if (e('_cb_slides').prop('checked'))
                        BRCommands.slideAction(undefined,undefined);
                    if (e('_cb_call').prop('checked')) {
                        BRCommands.clearAction('talking');
                        BRCommands.clearAction('member');
                        BRCommands.clearAction('lock');
                        BRCommands.conferenceAction('hup all');
                        }
                    if (e('_cb_online').prop('checked')) {
                        BRCommands.clearAction('video');
                        BRCommands.clearAction('gue');
                        BRCommands.clearAction('_');
                        BRCommands.commandAction('refresh');
                        }
                    if (e('_cb_oldusers').prop('checked')) {
                        for(var u in BRDashboard.boxes)
                            if (BRDashboard.boxes.hasOwnProperty(u) && BRDashboard.user_map[u] && !BRDashboard.user_map[u].email_address) {
                                var b  = BRDashboard.boxes[u];
                                if (!b.presence_count) {
                                    BRCommands.clearAction('users',u);
                                    BRCommands.clearAction('invitations',b.invitee_id);
                                    }
                                }
                        BRCommands.clearAction('pin');  /* while we're being scary... */
                        }
                    dlg.dialog('close');
                    });
                }
            });
    },

    _door: function() {
        var $j = jQuery, id='d';
        var startFn = null;
        var waitingForHost = false;
        var defaultButton = null;   /* which button is default for Enter on dialog? */
/*
        function detectHost2(o) {
            if (o.data && o.data.invitee_id && BRDashboard.invitees[o.data.invitee_id].role=='Host') {
                BRToolbar._doorAction('host');
                }
            }
*/
        function detectHost(o) {
            if (o.data._online > o.old_data._online) {
                var iid = BRDashboard.invitee_id_by_user[o.id]
                    , i = BRDashboard.invitees[iid];
                if (iid && i && i.role==="Host")
                    BRToolbar._doorAction('host');
                }
            }
        function setupWaitForHost() {
            BRDashboard.subscribe(detectHost,'box');
            waitingForHost = true;
            }
        function statusOn(id,msg,button) {
            jQuery('#'+id+'_status').text(msg);
            var pb = jQuery('#'+id+'_progress');
            pb.data("cs_timer", setInterval(function(){
                var val = pb.progressbar("option", "value");
                if (val<100)
                    pb.show().progressbar("option", "value", val+2);
                }, 20));
            //pb.progressbar("option","value",20).css('display','block');
            pb.progressbar("option","value",20).show();
            if (button)
                button.button("disable");
//            jQuery('#'+id+'_footer').show();
            }
        function statusOff(id,button) {
            var pb = jQuery('#'+id+'_progress');
            clearInterval(pb.data("cs_timer"));
            pb.progressbar("option","value",100);
//.progressbar("destroy");
            setTimeout(function(){
                //pb.css('display','none');
                pb.hide();
                }, 50);
            jQuery('#'+id+'_status').text('');
            if (button)
                button.button("enable");
//console.log( jQuery('#'+id+'_footer') );
//            jQuery('#'+id+'_footer').hide();
            }
        function set_error(pdlg, c, msg) {
            if (c) {
                if (msg) c+= '<br><p>['+msg+']</p>';
                c = '<div style="text-align: center;"><p>'+c+'</p>\
<p>Support information is available from the <a href="'+BR.api.v1.get_host('home')+'/faq/" style="font-weight: bold; color: black;">FAQ</a></p>\
</div>';
                $j('#'+id+'_error',pdlg).html(c).show();
                }
            else
                $j('#'+id+'_error',pdlg).html('').hide();
            }
        function checkInvitation(pdlg,d) {
            statusOff(id);
            if (!d)
                return BRToolbar._doorAction('fatal');

            var proto=null, dn=null, uri = null, ruri = null;
            if (/^(http|https):\/\/([^\/]+)\/([^#\?]+)(.*)$/.exec(document.URL)) {
                proto=RegExp.$1;
                dn=RegExp.$2;
                uri = RegExp.$3;
                /* the rest (query string etc.) in RegExp.$4; */
                }
            else 
                return BRToolbar._doorAction('fatal');
            if (/^([^\/]{4,})$/.exec(uri))
                ruri = uri
            else if (!/^i|byid\/(\d+)$/.exec(uri))
                return BRToolbar._doorAction('fatal');
{
/* playing around ... see how this works for us */
var qs = BRToolbar._getQueryString();
if (qs && qs['e']) {
    set_error(pdlg, decodeURIComponent(qs['e'])/*, system specific message ... */);
    }
}

            BRDashboard.parseAndSetAccessConfig(d.conference_access_config)
            var html=''
                //,   full_name = [(d.first_name||''),(d.last_name||'')].join(' ')
                //,   ca = (d.conference_access_config && JSON.parse(d.conference_access_config)) || {}
                //,   ca = BRDynamic.readOptions(d.conference_access_config, _br_v1_conference_options)
                ,   ca = BRDashboard.conference_access_config
                ,   hs = 'style="display: none;"'
                //,   hs = 'style="visibility: hidden;"'
                ;
//console.dir(BRDynamic.readDefaults(_br_v1_conference_options));
//            ca = $j.extend({}, BRDynamic.readDefaults(_br_v1_conference_options), ca);  /* is this necessary long-term? */
//console.dir(ca);
            html += '<div id="d_set_user"'+hs+'><p style="text-align: center;">Welcome '+d.user_name+', <a href="#" id="d_link_logout" class="br-blue">Not '+d.user_name+'?</a></p></div>';
            html += '<div id="d_set_conf"'+hs+'><p style="text-align: center;">'+(d.conference_name||'')+'</p><p>'+(d.conference_introduction||'')+'</p></div>';
            html += '<div id="d_set_private"'+hs+'><p style="text-align: center;">This is a private conference. Please contact the organizer for access.</p></div>';
            html += '<div id="d_set_invite"'+hs+'>This is a private conference, login to see if you have an invite</div>';
            html += '<div id="d_set_locked"'+hs+'>Entrance to this conference is currently restricted to hosts.</div>';
            html += '<div id="d_set_unknownnouser"'+hs+'><p><strong>'+document.location.href+'</strong> is not a valid conference URL</p>';
            if (!d.conference_id && !d.user_id && proto && dn && ruri) {
                /* this is actually (almost) overkill ... */
                html += ''
                    +'<p>Signup to reserve it now!</p>'
                    +'<a class="br-d-button" target="_blank" href="'+BR.api.v1.get_host('home')+'/signup/?room_url='+ruri+'"><i class="icon-ok pull-left"></i> Reserve '
                    +((proto==='https')?'<span class="secure-bright-green"><i class="icon-lock"></i> https</span>':'http')+'://'+dn+'/<strong>'+ruri+'</strong></a>';
                }
            html += '</div>';
            html += '<div id="d_set_unknown"'+hs+'>This is not a known conference</div>';
            html += '<div id="d_set_nick_intro"'+hs+'><p>Participants need to be identified in this room. You may enter a nickname or login if you have an account.</p></div>';
            html += '<div id="d_set_nick"'+hs+'><p style="text-align: center;"><label>Enter a Nickname<input id="d_input_nick" spellcheck="false" type="text" size="20" /></label><br>Have an account? <a href="#" class="br-blue br-d-login">Login</a><p></div>';
            html += '<div id="d_set_login"'+hs+'><center><table wdth="100%"><tr><td><label>Email<br><input id="d_input_email" style="margin-left:0;" type="text" size="20" spellcheck="false" /></label></td><td rowspan="2" width="10%"></td><td><label>Password<br><input id="d_input_password" style="margin-left:0;" type="password" size="20" spellcheck="false" /></label></td></tr><tr><td>Just use a <a href="#" id="d_link_nick" class="br-blue">Nickname</a></td><td><a href="'+BR.api.v1.get_host('my')+'/login?reset" class="br-blue" target="_blank">Forgot</a> password?</td></tr></table></center></div>';
            html += '<div id="d_set_wait"'+hs+'><center>Waiting for host to enter conference...<br><img src="'+BR.api.v1.get_host('cdn')+'/cdn/v1/c/img/bar-spinner.gif"></center></div>';
            html += '<p></p>';

            $j('#'+id+'_content').html(html).find('a.br-d-button').button();
            function show_nick() {
                jQuery('#d_set_login, #d_butt_login').hide();
                defaultButton = jQuery('#d_set_nick, #d_butt_start').show().last();
                //defaultButton  = jQuery('#d_butt_start');
                startFn = function() {
                    BR.api.v1.addSelf('/'+uri, {name: jQuery('#d_input_nick').val()}, {
                        fnerror: function(e){
                            set_error(pdlg,'<strong>Error setting nickname</strong>');
                            },
                        failure_url: uri+'?e='+encodeURIComponent('Error entering conference')
                        });
                    }
                }
            function show_login() {
                defaultButton = jQuery('#d_set_login, #d_butt_login').show().last();
                jQuery('#d_set_nick, #d_butt_start').hide();
                jQuery('#d_input_email').focus();
                startFn=null;
                }
            $j('.br-d-login',pdlg).click(function(){ show_login(); return false; });
            $j('#d_link_nick',pdlg).click(function(){ show_nick(); return false; });
            $j('#d_link_logout',pdlg).click(function(){ BR.api.v1.logout(); return false;});
/*
            // -- don't ask
            var tmp=$j('#d_link_nick').prop('tabindex');
            $j('#d_link_nick').prop('tabindex',$j('#d_input_password').prop('tabindex'));
            $j('#d_input_password').prop('tabindex',tmp);
            // -- !da
*/
            $j('#d_input_nick',pdlg).bind("keyup blur", function(){
                jQuery('#d_butt_start').button(this.value.length?'enable':'disable');
                });
            $j('#d_input_email,#d_input_password',pdlg).bind("keyup blur", function(){
                var ok = jQuery('#d_input_email').val() && jQuery('#d_input_password').val();
                jQuery('#d_butt_login').button((ok)?'enable':'disable');
                });

//       ********* remember !email_address == ephemeral ******* */
            /* door logic I */
            if (d.user_id) $j('#d_set_user').show();
            if (!d.conference_id) {
                if (!d.user_id) {   // **1**
                    $j('#d_set_unknownnouser').show();
                    }
                else {              // **2**
                    $j('#d_set_unknown').show();
                    }
                /* stop at this point, nothing else to do ... */
                return ;
                }
            else {
/*
                var redir = false;
                var urlChanges = {};
                /* this is how we would redirect back to page to fixup URL, not sure we'll do this as there may be some
                undesirable side-effects. Think I'm concerned about an infinite redirect loop -- guess we'll do it *./
                if (/*false &&*./d.conference_uri && d.conference_uri.length>=4 && uri!==d.conference_uri)
                    { redir=true; urlChanges['pathname']='/'+d.conference_uri; }
                if (window.location.search)
                    { redir=true; urlChanges['search']=''; }
                if (redir) {
                    window.location.href = BRToolbar._frankenURL(urlChanges);
                    return ;
                    }
*/
                if (ca.is_public || !ca.hide_details)
                    $j('#d_set_conf').show();
                else
                    $j('#d_set_private').show();
                }

            function do_start() {
                /* redirect to correct url */
                var redir = false;
                var urlChanges = {};
                /* this is how we would redirect back to page to fixup URL, not sure we'll do this as there may be some
                undesirable side-effects. Think I'm concerned about an infinite redirect loop -- guess we'll do it */
                if (/*false &&*/d.conference_uri && d.conference_uri.length>=4 && uri!==d.conference_uri)
                    { redir=true; urlChanges['pathname']='/'+d.conference_uri; }
                if (window.location.search)
                    { redir=true; urlChanges['search']=''; }
                if (redir) {
                    window.location.href = BRToolbar._frankenURL(urlChanges);
                    return ;
                    }
                /* actually start */
                BR.room.context = d;
                BRToolbar.setup();
        /*      BR.room.skin.id = BR.room.context.conference_skin_id; */
                BR.room.context.media_server_uri = encodeURIComponent('rtmp:' + BR.api.v1.get_host('video') + '/oflaDemo');   // yes, this is what is intended
                statusOn(id, 'Loading room...');
                BRCommands.start(BR.room.context.conference_estream_id, function(error){
                    /* only called on error */
                    BRToolbar._doorAction('fatal');
                    });
                }

            /* Recollection:
            At this point we know we have a valid conference
            */

            /* door logic II */
            if (d.user_id) {
                $j(".br-d-no-login",pdlg).hide();
                if (d.email_address)
                    $j(".br-d-non-ephemeral-logged-in",pdlg).show();
                if (d.invitation_id) {          // **3**
                    if (ca.is_locked && !d.is_host) {
                        $j("#d_set_locked",pdlg).show();
                        }
                    else {
                        if (ca.wait_for_host) { // **4**
                            $j('#d_set_wait').show();
                            setupWaitForHost();
                            }
                                                // **5** (not locked, don't wait for host)
                        do_start();
                        }
                    }
                else if (ca.is_public) {    // **4**
                    /* enable start button with associated action to self add invitation */
                    startFn = function() {
                        var success_url = BRToolbar._frankenURL({search:null});  /* drop query string */
                        BR.api.v1.addSelf('/'+uri, null, {success_url: success_url, failure_url: success_url+'?e='+encodeURIComponent('Error creating invitation')});
                        }
                    defaultButton = jQuery('#d_butt_start').button('enable');
                    }
                }
            else {
                $j(".br-d-no-login",pdlg).show();
                $j(".br-d-non-ephemeral-logged-in",pdlg).hide();
                // show login & signup anyhow ...
                //////$j('#d_set_login').show();
                if (ca.is_public) {
                    if (ca.require_nickname) {
                        // show nickname field
                        $j('#d_set_nick_intro').show();
                        show_nick();
                        }
                    else {
                        /* go right in ... */
                        BR.api.v1.addSelf('/'+uri, null, {failure_url: uri+'?e='+encodeURIComponent('Error entering conference')});
                        }
                    }
                else {
                    // private invitation only message
                    }
                }
            }
        BROverlays.generic({
            id: 'd',
            content: function(id) {
                return '\
<div class="ui-widget"><div id="'+id+'_error" class="ui-state-error ui-corner-all" style="display: none; padding 0 .7em; margin: 10px 0 15px 0;"></div></div>\
<div id="'+id+'_content">\
<!-- this splash also helps the initial positioning of the dialog -->\
<div style="text-align: center;"><i class="icon-comments" style="color: #5174a4; font-weight: bold; font-size: 1000%;"></i><br></div>\
</div>\
<div style="text-align: center;">\
 &nbsp; <button id="'+id+'_butt_reload"><i class="icon-refresh pull-left"></i> &nbsp; Reload</button>\
 &nbsp; <button id="'+id+'_butt_start" disabled><i class="icon-desktop pull-left"></i> &nbsp; Start</button>\
 &nbsp; <button id="'+id+'_butt_login" style="display: none;" disabled><i class="icon-key pull-left"></i> &nbsp; Login</button>\
</div>\
<div id="'+id+'_footer">\
<center><table width="80%" height="30"><tr><td width="50%"><div id="'+id+'_status" style=""></div></td><td width="50%"><div id="'+id+'_progress" style="height: 5px; display: none;"></div></td></tr></table>\
<span><a href="'+BR.api.v1.get_host('home')+'/home/" class="br-blue">Home</a>\
 &nbsp; &bull; &nbsp; </span>\
<span class="br-d-no-login"><a href="#" class="br-d-login br-blue">Login</a>\
 &nbsp; &bull; &nbsp; </span>\
<span class="br-d-no-login"><a href="'+BR.api.v1.get_host('home')+'/signup/" class="br-blue">Signup</a>\
 &nbsp; &bull; &nbsp; </span>\
<span class="br-d-non-ephemeral-logged-in"><a href="'+BR.api.v1.get_host('my')+'/" class="br-blue">Account</a>\
 &nbsp; &bull; &nbsp; </span>\
<span><a href="'+BR.api.v1.get_host('home')+'/faq/" class="br-blue">Help</a>\
 &nbsp; </span>\
</center>\
</div>\
';
            },
            logic:      function(id,selector) {
//                console.log(id,selector);
                var dlg = $j(selector), pdlg = dlg.parent();
                dlg.keypress(function(e){
                    if (e.keyCode === $j.ui.keyCode.ENTER && defaultButton)
                        return defaultButton.click() && false;
                    });
                $j(".br-d-no-login, .br-d-non-ephemeral-logged-in",pdlg).hide();
                $j('#'+id+'_progress').progressbar({value: 0});
                var sb = $j('#'+id+'_butt_start').button({disabled: true}).click(function(){
                    startFn && startFn();
                    });
                var lb = $j('#'+id+'_butt_login');
                lb.button({disabled: true}).hide().click(function(){
                    set_error(pdlg,'');
                    BR.api.v1.login({login: jQuery('#d_input_email').val(), password: jQuery('#d_input_password').val()}, {
                        fnerror:function(e){
                            if (e) set_error(pdlg,'Error logging in.',e);
                            else set_error(pdlg,'<strong>Login failed</strong>');
                            },
                        failure_url: BRToolbar._frankenURL({search:'?e='+encodeURIComponent("Login Failed")}),
                            });
                    });
                BRToolbar._doorAction = function(verb,arg) {
                    switch(verb) {
                        case 'badconference':
                            statusOff(id, sb);
                            jQuery('#'+id+'_status').text(verb);
                            break;
                        case 'fatal':
                            statusOff(id);
                            /* this is where we end up if we couldn't even get the invitation row */
                            set_error(pdlg,'An error occurred accessing the conference. You may click the <strong>Reload</strong> button to try again.',arg);
                            break;
                        case 'invitation':
                            statusOff(id);
                            checkInvitation(pdlg,arg);
                            break;
                        case 'loaded':
                        case 'host':
                            statusOff(id);  /* loaded, but leave start button off */
//console.log(verb,waitingForHost);
                            if ((verb==='host')===waitingForHost) {
                                statusOff(id, sb);
                                $j('.ui-dialog-titlebar-close',pdlg).show();
                                setTimeout(function(){dlg.dialog("close");},100);
                                }
                            break;
                        }
                    }
                $j('#'+id+'_butt_reload').button().click(function(){
                    BRToolbar.pageReload();
                    });
                statusOn(id, 'Checking access...', sb);
                $j('button',pdlg).blur();
                },
            title:  'Welcome',
            dialogOpts: {
                closeOnEscape: false,
                /*dialogClass: "no-close", -- this actually doesn't work ... */
                open: function(event,ui) { $j('.ui-dialog-titlebar-close', this.dialog).hide(); },
                close: function(event,ui) { BRDashboard.unsubscribe(detectHost); BRToolbar._doorAction = function(){}; },
                width: '300px'
                }
            });
    },

    door: function(verb,arg) {
        switch(verb) {
            case 'open': BRToolbar._door(); break;
            default: 
                BRToolbar._doorAction(verb,arg);
            }
    }
}

