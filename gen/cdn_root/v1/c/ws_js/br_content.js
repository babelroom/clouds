var BRContent = {

    content_addGuests: function(id) {
        return '\
            <table id="'+ id +'_root" cellpadding="4" cellspacing="0" border="0" width="100%"><tr valign="top"><td width="100">\
            <div id="' + id + '_finder_tabs" style="border: none;">\
                <ul>\
                    <li><a href="#' + id + '_finder_tabs-1">Guests</a></li>\
                    <li><a href="#' + id + '_finder_tabs-2" style="display:none;">Find</a></li>\
                </ul>\
                <div id="' + id + '_finder_tabs-1">\
                    <p><select id="'+id+'_guests" size="10" width="100%"><option value="-1">-- New Guest --</option></select></p>\
                </div>\
                <div id="' + id + '_finder_tabs-2">\
                    <label class="label_text">eMail<input id="' + id + '_finder" type="text" value="" /></label>\
                </div>\
            </div>\
            </td><td>\
            <div id="' + id + '_tabs" style="border: none;">\
                <ul>\
                    <li><a href="#' + id + '_tabs-1">Call</a></li>\
                    <li><a href="#' + id + '_tabs-2" style="display:none;">eMail</a></li>\
                </ul>\
                <div id="' + id + '_tabs-1">\
                    <input id="'+id+'_first_name" type="text" placeholder="First name" spellcheck="false" disabled>\
                    <input id="'+id+'_last_name" type="text" placeholder="Last name" spellcheck="false" disabled><p>\
                    <select id="' + id + '_country" class="br-select" disabled><option value="">-- Select --</option></select>\
                    <input id="' + id + '_prefix" size="3" readonly disabled>\
                    <input id="' + id + '_number" spellcheck="false" type="text" size="12" disabled><p>\
                    <span style="float: left;" class="host-only">PIN <span id="'+id+'_pin"></span><span id="'+id+'_status"></span></span><p>\
                    <span style="float: right;"><input id="'+id+'_call" type="button" value="Call"></span><p>\
                    <div style="height: 80px;"></div>\
                </div>\
                <div id="' + id + '_tabs-2">\
                    <table cellpadding="10" cellspacing="10" border="0">\
                        <tr>\
                            <td><b>Email addresses</b></td>\
                            <td><input name="email_addresses"></td>\
                        </tr>\
                        <tr>\
                            <td><b>Subject</b></td>\
                            <td><input name="subject"></td>\
                        </tr>\
                        <tr>\
                            <td colspan="2"><b>Message</b><br />\
                            <textarea></textarea><br />\
                            Copy to clipboard</td>\
                        </tr>\
                    </table>\
                </div>\
            </div>\
            </td></tr></table>\
            ';
        },

    content_connect: function(id, webcall_url) {
        var $j = jQuery;
        var html = '\
            <div id="' + id + '_tabs" style="border: none;">\
                <ul>\
                    <li><a href="#' + id + '_tabs-1">Dial-in Information</a></li>\
                    <li><a href="#' + id + '_tabs-2">Call My Number</a></li>\
                    <li><a href="#' + id + '_tabs-3">Call My Computer</a></li>\
                </ul>\
                <div id="' + id + '_tabs-1">\
                    <table cellpadding="4" cellspacing="0" border="0" width="100%">\
                        <tr>\
                            <td><b>Access Number</b></td>\
                            <!--<td><textarea rows="5" cols="40" disabled>' + BR.room.context.myAccessInfo + '</textarea></td>-->\
                            <td>' + BR.room.context.myAccessInfo + '</td>\
                        </tr>\
                        <tr>\
                            <td colspan="2">&nbsp;</td>\
                        </tr>\
                        <tr>\
                            <td><b>PIN code</b></td>\
                            <td>' + BR.room.context.pin + '</td>\
                        </tr>\
                        <tr>\
                            <td colspan="2">&nbsp;</td>\
                        </tr>\
                        <tr>\
                            <td><b>SIP (VoIP)</b></td>\
                            <td>' + BR.room.context.pin + '@sip.babelroom.com</td>\
                        </tr>\
                    </table>\
                </div>\
                <div id="' + id + '_tabs-2">\
    <table cellspacing="0" cellpadding="10" border="0" width="100%">\
        <tr>\
            <th width="10px"></th>\
            <th width="190px"></th>\
            <th width="0px"></th>\
            <th width="95px"></th>\
            <th width="95px"></th>\
            <th width="10px"></th>\
        </tr>\
        <tr>\
            <td></td>\
            <td colspan="1" style="padding: 10px;"><label>Country / Region<br /><select id="' + id + '_country" class="br-select" disabled><option value="">-- Select --</option></select></label></td>\
            <td></td>\
            <td colspan="2" style="padding: 10px;"><label>Phone Number<br /><input id="'+id+'_code" size="3" readonly disabled value=""><input id="' + id + '_number" spellcheck="false" type="text" size="12" value="Loading..." disabled></label></td>\
            <td></td>\
        </tr>\
        <tr>\
            <td></td>\
            <td colspan="3" style="padding: 10px;"><label syle="font-size: 14px;" clss="cs_white shadow"><input type="checkbox" id="' + id + '_save">Remember this number</label></td>\
            <td><div id="'+id+'_saved" style="color: #c4e913; display: none;"><b>Saved</b></div></td>\
            <td></td>\
        </tr>\
        <tr>\
            <td></td>\
            <td colspan="3" style="padding: 10px; fnt-size: 14px;" align="center">\
                <table cellpadding="0" cellspacing="0" width="100%"><tr><td width="width:20px; align:left;"><div id="'+id+'_callme_spinner"></div></td><td><div id="'+id+'_callme_status"></div></td></tr></table>\
            </td>\
            <td colspan="1" style="padding: 10px; fnt-size: 14px;" align="right">\
                <input type="button" value="Dial" id="' + id + '_dial" disabled>\
            </td>\
            <td></td>\
        </tr>\
    </table>\
                </div>\
                <div id="' + id + '_tabs-3">\
                    <iframe frameBorder="0" src="'+webcall_url+'" style="height: 200px; width: 520px;">\
                    </iframe>\
                </div>\
            </div>\
            ';
        return html;
    },

    content_connect_jquery: function(id, webcall_url) {
        return BRContent.content_connect(id, webcall_url);
        },

    content_connectLogic: function(id,win) {
        var $j = jQuery, tsel='#'+id+'_tabs', tab3sel=tsel+'-3';
        $j(tsel).tabs(/*(2, ????*/ {
/* --- apparently not needed
            show: function(e, u) {
console.log(u);
                    if (win) {
                        setTimeout(function(){
                            var divid = $(id + "_tabs");
                            // var divid = u.panel.id
                            if ($(divid).offsetHeight>0 && $(divid).offsetWidth>0) {
                                win.setSize($(divid).offsetWidth,$(divid).offsetHeight);
                                }
                            },0);
                        }
                    },
*/
            beforeActivate: function(e,u) {         /* all because flash leaves screen artifacts */
                if (u.oldPanel.selector==tab3sel) {
                    if ($j(tab3sel).data('br-offset'))
                        return true;
//console.log(u);
                    /* don't ask */
                    var o=$j(tab3sel).offset(), op=$j(tab3sel).parent().offset();
                    o.top -= op.top; o.left -= op.left;
                    $j(tab3sel).data('br-offset', o);
/*console.log( $j(tab3sel) );
console.log( $j(tab3sel).parent() );
console.log( $j(tab3sel).parent().offset() );
console.log( $j(tab3sel).offset() ); */
                    var idx = $j(u.newPanel.selector).data('br-idx');
//console.log(tsel);
                    setTimeout(function(){$j(tsel).tabs("option","active",idx);}, 0);
                    setTimeout(function(){$j(tsel).tabs("option","active",idx);}, 100);
                    $j(tab3sel).offset({top: -5000, left: -5000});
                    return false;
//console.log(1,$j(tab3sel).offset());
                    }
                return true;
                },
            activate: function(e,u) {
                if (u.newPanel.selector==tab3sel) {
                    var o;
                    if ((o=$j(tab3sel).data('br-offset'))) {
                        var op=$j(tab3sel).parent().offset();
                        o.top += op.top; o.left += op.left;
                        $j(tab3sel).offset(o).data('br-offset', null);
                        }
                    }
                }
            });
        $j(tsel+'-1').data('br-idx',0);
        $j(tsel+'-2').data('br-idx',1);
        $j(tab3sel).data('br-offset',null);
        var countries = BR.room.countries;
        if (countries.length>0) {
            var csel=jQuery('#'+id+'_country');
            for(var i=0; i<countries.length; i++) {
                csel.append('<option value="+'+countries[i].code+'">'+countries[i].name+'</option>');
                }
            csel.prop('disabled',false);
            }

/*
        var timer = null;
        win.dispatchCh = 'K';
        win.dispatchFn = function(str) {
            }
        win.resetFn = function() {
            }
*/

        var update = function() {
//            var button = jQuery('#'+id+'_dial');
            if (    jQuery('#'+id+'_code').val().length>0 &&
                    jQuery('#'+id+'_number').val().length>0 && 
                    jQuery('#'+id+'_callme_status').text().length==0 ) {
                //jQuery('#'+id+'_dial').attr('disabled','');
                $j('#'+id+'_dial').button('enable');
//                button.addClass('black');
//                button.removeClass('grey');

                }
            else {
                //jQuery('#'+id+'_dial').attr('disabled','disabled');
                $j('#'+id+'_dial').button('disable');
//                button.addClass('grey');
//                button.removeClass('black');
                }
//            jQuery('#'+id+'_saved').css('display','none');
            }
        fn_country = function () {
            var code = jQuery('#'+id+'_country').val();
            jQuery('#'+id+'_code').val(code);
            jQuery('#'+id+'_saved').css('display','none');
            update();
            }
        $j('#'+id+'_country').change(fn_country);
        fn_number = function() {
            jQuery('#'+id+'_saved').css('display','none');
            update();
            }
        $j('#'+id+'_number').keyup(fn_number);
        fn_dial = function() {
//alert($);
//$ = jQuery.noConflict();
            var save = jQuery('#'+id+'_save').attr('checked');
            var phone_number = jQuery('#'+id+'_number').val().replace(/[^\d#]/g,'');
            jQuery('#'+id+'_number').val(phone_number);
            if (phone_number.length==0) {
                update();
                return;
                }
            var full_number = jQuery('#'+id+'_code').val() + phone_number;
            spin(true);
            text('Dialing...');
            update();
            if (save) {
                text('Saving...');
                BRUtils.aq(3, {f:{phone:full_number},id:BR.room.context.user_id}, function (data, textStatus) {
                        if (textStatus=='success') {
                            jQuery('#'+id+'_saved').css('display','block');
                            update();
                        }
                    });
                }
            text('Dialing...');
            var pin = BR.room.context.pin;
            var pin_val = jQuery('#'+id+'_pin').val();
            if (pin_val && pin_val.length>0) {
                pin = pin_val;
                }
            BRCommands.fsDialout(pin,full_number,'Babelroom',BRUtils.makeDialToken());
            text('');
            spin(false);
            update();
            $j('#'+id+'_overlay').dialog('close');
            }
        $j('#'+id+'_dial').button().click(fn_dial);
        var spin = function(do_spin) { jQuery('#'+id+'_callme_spinner').html(do_spin ?  "<img src='"+BR.api.v1.get_host('cdn')+"/cdn/v1/c/img/arrows_spinner.gif' alt='' />" : ""); }
        var text = function(text, bgcolor) {
            jQuery('#'+id+'_callme_status').html(text);
            if (bgcolor!=undefined) {
                jQuery('#'+id+'_callme_status').css('background-color',bgcolor);
                }
            }
        var msg = "Loading.";
        spin(true);
        text('Loading...');
//        Application.replayData(win);
        BRUtils.aq(1, {ah:[BR.room.context.user_id]}, function (data, textStatus) {
                spin(false);
                text('');
                if (textStatus=='success') {
                    var result = eval(data);
                    var full_number = result[0].user.phone;
                    if (full_number==null)
                        full_number='';
                    var phone_number = full_number;
                    for(i=2; i<Math.min(5,full_number.length); i++) { // try to match increasing long prefixes in dropdown
                        var prefix = full_number.substr(0,i);
                        jQuery('#'+id+'_country').attr('value',prefix);
                        prefix = jQuery('#'+id+'_country').attr('value');
                        if (prefix.length>0) {
                            jQuery('#'+id+'_code').val(prefix);
                            phone_number = full_number.substr(i);
                            break;
                            }
                        }
                    jQuery('#'+id+'_number').val(phone_number);
                    jQuery('#'+id+'_number').prop('disabled',false);
                    update();
                    }
                else if (textStatus=='error') {
                    // -- ?? TODO
                    }
                });
    },



    content_breakoutGroups: function(id,selector) {
        return '\
<div id="'+selector+'" style="overflow: visible;">\
    <fieldset class="ui-widget ui-widget-content"><legend id="'+id+'_selected" class="ui-widget-header ui-corner-all">.</legend>\
        <table width="100%" cellpadding="0" cellspacing="0">\
        <tr><th width="10%"></th><th width="70%"></th><th width="20%"></th></tr>\
        <tr><td></td><td><select id="'+id+'_move" style="width: 100%;">\
                        <option selected value="-1">-- Select --</option>\
                        <option value="0">Main Group</option>\
                        <option value="1">-- Group 1</option>\
                        <option value="2">-- Group 2</option>\
                        <option value="3">-- Group 3</option>\
                        <option value="4">-- Group 4</option>\
                        <option value="5">-- Group 5</option>\
                        <option value="6">-- Group 6</option>\
                        <option value="7">-- Group 7</option>\
                        <option value="8">-- Group 8</option>\
                        <option value="9">-- Group 9</option>\
                        </select></td><td><button id="'+id+'_move_button">Move</button></td></tr>\
            </td>\
        <tr><td></td><td><select id="'+id+'_break" style="width: 100%;">\
                        <option selected value="-1">- Break into -</option>\
                        <option value="2">Groups of 2</option>\
                        <option value="3">Groups of 3</option>\
                        <option value="4">Groups of 4</option>\
                        <option value="5">Groups of 5</option>\
                        <option value="6">Groups of 6</option>\
                        <option value="7">Groups of 7</option>\
                        <option value="8">Groups of 8</option>\
                        <option value="9">Groups of 9</option>\
                        <option value="10">Groups of 10</option>\
                        <option value="102">2 Groups</option>\
                        <option value="103">3 Groups</option>\
                        <option value="104">4 Groups</option>\
                        <option value="105">5 Groups</option>\
                        <option value="106">6 Groups</option>\
                        <option value="107">7 Groups</option>\
                        <option value="108">8 Groups</option>\
                        <option value="109">9 Groups</option>\
                        <option value="110">10 Groups</option>\
                        </select></td><td><button id="'+id+'_break_button">Break</button></td></tr>\
        </table><br>\
    </fieldset>\
    <center><button id="'+id+'_return_button" class="need1caller" title="Move all participants back to main room">Move all to Main Room</button></center>\
</div>';
    },

    content_dialpad: function(id,selector) {
        return '\
<div id="'+selector+'">\
    <div id="controls" class="button">\
       <table id="'+id+'_keypad" class="dtmftable" cols=3 border=0 cellpadding="0" cellspacing="0">\
            <tr class="dtmfrow">\
                <td class="dtmfcell" colspan="3">\
                    <span style="white-space:nowrap;">\
                    <input type="text" class="br-phone-display" style="width: 0.75em; border-right: 0; margin-right: 0;" value="+" disabled \
                    /><input type="text" name="number" class="br-phone-display" style="border-left: 0; margin-left: 0; width: 160px;" value="1" sze="16"/>\
                    </span>\
                </td>\
            </tr>\
            <tr class="dtmfrow" style="height: 10px;"></tr>\
            <tr class="dtmfrow">\
                <td class="dtmfcell"><button id="'+id+'_talk" class="dtmfkey" value="T" title="Dial"><i class="icon icon-phone" style="color: lime;"></i></td>\
                <td class="dtmfcell"><button class="dtmfkey" value="D" title="Delete"><i class="icon icon2-erase"></i><span class="f6wn">&nbsp;DEL</span></button></td>\
                <td class="dtmfcell"><button class="dtmfkey" value="C" title="Clear"><span class="f6wn">CLEAR</span></td>\
            </tr>\
            <tr class="dtmfrow" style="height: 10px;"></tr>\
            <tr class="dtmfrow">\
                <td class="dtmfcell"><button class="dtmfkey" value="1" title="1">1<span class="f6wn">&nbsp;&nbsp;&nbsp;&nbsp;</span></button></td>\
                <td class="dtmfcell"><button class="dtmfkey" value="2" title="2">2<span class="f6wn">&nbsp;ABC</span></button></td>\
                <td class="dtmfcell"><button class="dtmfkey" value="3" title="3">3<span class="f6wn">&nbsp;DEF</span></button></td>\
            </tr>\
            <tr class="dtmfrow">\
                <td class="dtmfcell"><button class="dtmfkey" value="4" title="4">4<span class="f6wn">&nbsp;GHI</span></button></td>\
                <td class="dtmfcell"><button class="dtmfkey" value="5" title="5">5<span class="f6wn">&nbsp;JKL</span></button></td>\
                <td class="dtmfcell"><button class="dtmfkey" value="6" title="6">6<span class="f6wn">&nbsp;MNO</span></button></td>\
            </tr>\
            <tr class="dtmfrow">\
                <td class="dtmfcell"><button class="dtmfkey" value="7" title="7">7<span class="f6wn">&nbsp;PQRS</span></button></td>\
                <td class="dtmfcell"><button class="dtmfkey" value="8" title="8">8<span class="f6wn">&nbsp;TUV</span></button></td>\
                <td class="dtmfcell"><button class="dtmfkey" value="9" title="9">9<span class="f6wn">&nbsp;WXYZ</span></button></td>\
            </tr>\
            <tr class="dtmfrow">\
                <td class="dtmfcell"><button class="dtmfkey" value="*" title="*">*</button></td>\
                <td class="dtmfcell"><button class="dtmfkey" value="0" title="0">0 +</button></td>\
                <td class="dtmfcell"><button class="dtmfkey" value="#" title="#">#</button></td>\
            </tr>\
            <tr class="dtmfrow" style="height: 10px;"></tr>\
        </table>\
    </div>\
    <div id="call_monitor">\
    </div>\
</div>';
    },

    content_controls: function(id,selector) {
        return '\
<div id="'+selector+'">\
    <fieldset class="ui-widget ui-widget-content"><legend id="'+id+'_selected" class="ui-widget-header ui-corner-all">.</legend>\
        <span>Mic Volume: </span><span id="'+id+'_volume_in_level_text">0 (normal)</span><select id="'+id+'_volume_in_level" style="display: none;">\
        <option value="-4">-4 (lowest)</option>\
        <option value="-3">-3</option>\
        <option value="-2">-2</option>\
        <option value="-1">-1</option>\
        <option value="0" selected>0 (normal)</option>\
        <option value="1">1</option>\
        <option value="2">2</option>\
        <option value="3">3</option>\
        <option value="4">4 (highest)</option>\
        </select>\
        <p>\
        <div id="'+id+'_volume_in" width="90%"></div>\
        <br />\
        <div style="float: left;"><button id="'+id+'_mute" style="width: 75px;" title="Mute">Mute</button></div>\
        <div style="float: right;"><button id="'+id+'_unmute" style="width: 75px;" title="Unmute">Unmute</button></div>\
        <br />\
        <div style="float: left;"><button id="'+id+'_pa" style="width: 75px;" title="Enable broadcast to all participants"><i class="icon-bullhorn pull-left"></i> PA on</button></div>\
        <div style="float: right;"><button id="'+id+'_unpa" style="width: 75px;" title="Disable broadcast to all participants">PA off</button></div>\
        <br />\
        <div style="float: left;"><button id="'+id+'_drop" style="width: 75px;" title="Drop selected participant(s) from call">Drop</button></div>\
    </fieldset>\
    <fieldset class="ui-widget ui-widget-content"><legend id="'+id+'_recording" class="ui-widget-header ui-corner-all">.</legend>\
        <div style="float: left;"><button id="'+id+'_start_recording" class="need1caller" style="width: 160px;" title="Start recording audio">Start Recording</button></div>\
        <div style="float: left;"><button id="'+id+'_stop_recording" class="need1caller" style="width: 160px;" title="End recording audio">Stop Recording</button></div>\
    </fieldset>\
    <fieldset class="ui-widget ui-widget-content"><legend class="ui-widget-header ui-corner-all">Conference</legend>\
        <div style="float: left;"><button id="'+id+'_lock" class="need1caller" style="width: 75px;" title="Lock access to conference">Lock</button></div>\
        <div style="float: left;"><button id="'+id+'_unlock" class="need1caller" style="width: 75px;" title="Unlock access to conference">Unlock</button></div>\
        <div style="float: right;"><button id="'+id+'_end_call" class="need1caller" style="width: 75px;" title="End conference">End</button></div>\
    </fieldset>\
                        <!-- note may be removed ... -->\
    <div id="'+id+'_confirm" title="End the conference now?" style="display: none;">\
        <p><span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>The conference will be ended, all callers disconnected and recordings will be stopped.</p>\
    </div>\
</div>';
    },

    content_polling: function(id,selector) {
        return '\
<div id="'+selector+'">\
    <table width="100%" cellpadding="0">\
        <tr align="center"><th width="25%"></th><th width="25%">Count</th><th width="25%">% of Poll</th><th width="25%">% of Voters</th></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_"></td><td  id="'+id+'_c_"></td><td  id="'+id+'_p_"></td><td  id="'+id+'_v_"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_0">No vote</td><td  id="'+id+'_c_0"></td><td  id="'+id+'_p_0"></td><td  id="'+id+'_v_0"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_1">1</td><td  id="'+id+'_c_1"></td><td  id="'+id+'_p_1"></td><td  id="'+id+'_v_1"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_2">2</td><td  id="'+id+'_c_2"></td><td  id="'+id+'_p_2"></td><td  id="'+id+'_v_2"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_3">3</td><td  id="'+id+'_c_3"></td><td  id="'+id+'_p_3"></td><td  id="'+id+'_v_3"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_4">4</td><td  id="'+id+'_c_4"></td><td  id="'+id+'_p_4"></td><td  id="'+id+'_v_4"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_5">5</td><td  id="'+id+'_c_5"></td><td  id="'+id+'_p_5"></td><td  id="'+id+'_v_5"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_6">6</td><td  id="'+id+'_c_6"></td><td  id="'+id+'_p_6"></td><td  id="'+id+'_v_6"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_7">7</td><td  id="'+id+'_c_7"></td><td  id="'+id+'_p_7"></td><td  id="'+id+'_v_7"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_8">8</td><td  id="'+id+'_c_8"></td><td  id="'+id+'_p_8"></td><td  id="'+id+'_v_8"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_9">9</td><td  id="'+id+'_c_9"></td><td  id="'+id+'_p_9"></td><td  id="'+id+'_v_9"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_10">Voted</td><td  id="'+id+'_c_10"></td><td  id="'+id+'_p_10"></td><td  id="'+id+'_v_10"></td></tr>\
        <tr align="center"><td align="right" id="'+id+'_t_11">Total</td><td  id="'+id+'_c_11"></td><td  id="'+id+'_p_11"></td><td  id="'+id+'_v_11"></td></tr>\
    </table>\
    <button id="'+id+'_clear_button" title="Reset poll results">Clear</button>\
</div>';
    },

    content_systemControls: function(id,selector) {
        return '\
<div id="'+selector+'">\
    <fieldset class="ui-widget ui-widget-content"><legend id="'+id+'_selected" class="ui-widget-header ui-corner-all">.</legend>\
    <table width="100%" cellpadding="5">\
        <tr><th width="10%"></th><th width="70%"></th><th width="20%"></th></tr>\
        <tr><td>Vout</td><td><div id="'+id+'_volume_out"></div></td><td id="'+id+'_volume_out_level">0</td></tr>\
        <tr><td>Energy</td><td><div id="'+id+'_volume_en"></div></td><td id="'+id+'_volume_en_level">300</td></tr>\
    </table>\
        <center><button id="'+id+'_deaf" title="Silence audio to participant(s)">Deaf</button>\
        <button id="'+id+'_undeaf" title="Unblock audio to participant(s)" >Undeaf</button></center>\
    </fieldset>\
</div>';
    },

    content: function(content,id) {
        switch(content) {
            case 'guests': return BRContent.content_addGuests(id);
            case 'guests_jquery': return BRContent.content_addGuests(id);
/*            case 'participantControls': return Application.content_participantControls(id); */
            }
    }
}

