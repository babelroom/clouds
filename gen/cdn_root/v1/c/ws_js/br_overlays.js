var BROverlays = {

    connect_overlay: null,

    connect_depreciated: function(props) {
        var $j = jQuery;
        var myid = BROverlays.connect_overlay;
        if (myid===null) {
            myid = BRWidgets.nextId();
            BROverlays.connect_overlay = myid;
            $j("body").append('<div id="'+myid+'_overlay" style="display: none;" class="cs_overlay">'+BRContent.content_connect(myid,props.webcall_url)+'</div>');
            $j('#'+myid+'_overlay').overlay({
                /* top: 260, */

                mask: {
                    // you might also consider a "transparent" color for the mask
                    color: '#555',
                    // load mask a little faster
                    loadSpeed: 200,
                    // very transparent
                    opacity: 0.7
                    },

                /* closeOnClick: false,       no, like zendesk */
                closeOnClick: false,    /* yes, not like zendesk */
                load: true
                });
            BRContent.content_connectLogic(myid);
            }
        else {
            $j('#'+myid+'_overlay').overlay().load();
            }
        if (props.selected_tab) {
            $j("#" + myid + "_tabs").tabs('select', props.selected_tab-1);
            }
    },

    connect: function(props) {
        var $j = jQuery;
        var myid = BROverlays.connect_overlay;
        if (myid===null) {
            myid = BRWidgets.nextId();
            BROverlays.connect_overlay = myid;
            $j("body").append('<div id="'+myid+'_overlay" style="display: none;" title="Connect">'+BRContent.content_connect_jquery(myid,props.webcall_url)+'</div>');
            $j('#'+myid+'_overlay').dialog({
                modal: true,
                width: 'auto',
                beforeClose: function(e, ui) {      /* record coordinates of dialog before allowing it to close */
                    /* hack to workaround flash object leaving screen artifacts.
                    1. if second time around (!!offset) allow dialog to close
                    2. if first time around, record the dialog position, move it offscreen, then set a timer with short interval to re-issue the close dialog event
                    */
                    var dlg = $j('#'+myid+'_overlay'), pdlg = dlg.parent(), offset = dlg.data('br-offset');
//console.log(0,offset);
                    if (offset)
                        return true;
                    dlg.data('br-offset', pdlg.offset());
                    pdlg.offset({top: -5000, left: -5000});
                    setTimeout(function(){ dlg.dialog('close');}, 0);   /* 0 too short, only works 50% on chrome */
                    setTimeout(function(){ dlg.dialog('close');}, 100); /* with both works 100% -- although if you inspect code, shouldn't make any difference... */
                    /* dlg.dialog('close'); -- certainly doesn't work - for obvious reasons */
//console.log(2);
                    return false;
                    }
                }).data('br-offset', null);
            BRContent.content_connectLogic(myid);
            }
        else {
            var dlg = $j('#'+myid+'_overlay'), pdlg = dlg.parent(), offset = dlg.data('br-offset');
//console.log(3,offset);
            if (offset) {
                /* restore dialog to its previous position */
                pdlg.offset(offset);
                dlg.data('br-offset', null);
                }
//console.log(4);
            dlg.dialog("open");
            }
        if (props.selected_tab) {
            $j("#" + myid + "_tabs").tabs("option", "active", props.selected_tab-1);
            }
    },

    guests_depreciated: function() {
        var myid = BRWidgets.nextId();
        var $j = jQuery;
        $j("body").append('<div id="'+myid+'_overlay" style="display: none;" class="cs_overlay">'+BRContent.content('guests',myid)+'</div>');
        $j('#'+myid+'_overlay').overlay({
            /* top: 260, */

            mask: {
                // you might also consider a "transparent" color for the mask
                color: '#555',
                // load mask a little faster
                loadSpeed: 200,
                // very transparent
                opacity: 0.7
                },

            /* closeOnClick: false,       no, like zendesk */
            closeOnClick: false,    /* yes, not like zendesk */
            load: true
            });
        $j("#" + myid + "_tabs").tabs();
        jQuery("#" + myid + "_finder_tabs").tabs();
        BRInvitees.dashboard_add_guests({
            root: '#'+myid+'_root',
            id: myid,
            guests: '#'+myid+'_guests',
            call: '#'+myid+'_call'
            });
    },

    guests: function() {
        var myid = BRWidgets.nextId();
        var $j = jQuery;
        $j("body").append('<div id="'+myid+'_overlay" style="display: none;" title="Guests">'+BRContent.content('guests_jquery',myid)+'</div>');
        $j('#'+myid+'_overlay').dialog({
            modal: true,
            width: 'auto'
            });
        $j("#" + myid + "_tabs").tabs();
        jQuery("#" + myid + "_finder_tabs").tabs();
        BRInvitees.dashboard_add_guests({
            root: '#'+myid+'_root',
            id: myid,
            guests: '#'+myid+'_guests',
            call: '#'+myid+'_call'
            });
    },

    conference_settings_depreciated: function() {
        var myid = BRWidgets.nextId();
        var $j = jQuery;
        $j("body").append('<div id="'+myid+'_overlay" style="display: none;" class="cs_overlay">'+BRConference.conference_settings_html(myid)+'</div>');
        $j('#'+myid+'_overlay').overlay({
            /* top: 260, */

            mask: {
                // you might also consider a "transparent" color for the mask
                color: '#555',
                // load mask a little faster
                loadSpeed: 200,
                // very transparent
                opacity: 0.7
                },

            /* closeOnClick: false,       no, like zendesk */
            closeOnClick: false,    /* yes, not like zendesk */
            load: true
            });
        BRConference.conference_settings_logic({
            id: myid,
            root: '#'+myid+'_overlay'
            });
    },

    conference_settings: function() {
        var myid = BRWidgets.nextId();
        var $j = jQuery;
        /* NOTE: the overflow-x here might not work in all browsers cases ... */
        $j("body").append('<div id="'+myid+'_overlay" style="display: none; overflow-x: hidden;" title="Room Settings">'+BRConference.conference_settings_html(myid)+'</div>');
        var access_tree = BRDynamic.populateHTML(myid+'_access_', _br_v1_conference_options);
        $j('#'+myid+'_access').prepend(access_tree.html/*+'<br><center><button>Save</button></center>'*/);
        $j('#'+myid+'_overlay').dialog({
            modal: true,
            width: 'auto',
            //width: '400px',
            beforeClose: function(e,u) {
//                console.log(e,u);  
//                return false; <--- this cancels close
                }
            });//.children(':first-child').css('border','none');
        BRConference.conference_settings_logic({
            id: myid,
            root: '#'+myid+'_overlay',
            access_tree: access_tree
            });
    },

    generic_old_and_depreciated: function(o) {
        var myid = BRWidgets.nextId();
        var $j = jQuery;
        $j("body").append('<div id="'+myid+'_overlay" style="display: none;" class="cs_overlay"><div id="content"></div></div>');
        $j('#'+myid+'_overlay').overlay({
            mask: {
                // you might also consider a "transparent" color for the mask
                color: '#555',
                // load mask a little faster
                loadSpeed: 200,
                // very transparent
                opacity: 0.7
                },
onBeforeLoad: function() {
            // grab wrapper element inside content
            var wrap = this.getOverlay().find("#content");

            // load the page specified in the trigger
            wrap.load(o.url+'.html').css('display','block');
},
            closeOnClick: false,
            load: true
            //load: false
            });
            //}).load(o.url+'.html');
    },
    
    generic_depreciated: function(o) {
        var myid = BRWidgets.nextId();
        var $j = jQuery;
        $j("body").append('<div id="'+myid+'_overlay" style="display: none;" class="cs_overlay">'+o.content(myid)+'</div>');
        $j('#'+myid+'_overlay').overlay({
            mask: {
                // you might also consider a "transparent" color for the mask
                color: '#555',
                // load mask a little faster
                loadSpeed: 200,
                // very transparent
                opacity: 0.7
                },
/*
NB -- so the problem with doing it this way it fp actually injects the url content into the
current page -- in this environment that frequently results in all sorts of style / css collisions

onBeforeLoad: function() {
            // grab wrapper element inside content
            var wrap = this.getOverlay().find("#content");

            // load the page specified in the trigger
            wrap.load(o.url+'.html').css('display','block');
},
*/
            /* closeOnClick: false,       no, like zendesk */
            closeOnClick: false,    /* yes, not like zendesk */
            load: true
            //load: false
            });
        o.logic(myid, '#'+myid+'_overlay');
    },
    
    generic: function(o) {
        var myid = o.id || BRWidgets.nextId()
                    ,   $j = jQuery
                    ,   title = ''
                    ;
        if (o.title)
            title = ' title="'+o.title+'"';
        $j("body").append('<div id="'+myid+'_overlay" style="display: none;"'+title+'>'+o.content(myid)+'</div>');
        $j('#'+myid+'_overlay').dialog($j.extend({
            modal: true,
            width: 'auto'
            },o.dialogOpts));
/*
            /* closeOnClick: false,       no, like zendesk *./
            closeOnClick: false,    /* yes, not like zendesk *./
            load: true
            //load: false
            }); */
        o.logic(myid, '#'+myid+'_overlay');
    }
};


