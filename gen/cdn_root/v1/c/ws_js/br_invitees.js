var BRInvitees = {

    aj: function(url,args,done) {
/* TODO ... just a little later
        jQuery.ajax({
            url: url,
            type: "POST",
            data: args,
            success: done,
            error: function (jqXHR, textStatus, errorThrown) { done(errorThrown, textStatus, jqXHR); }
            });
*/
        },

    dashboard_phone_fieldset: function(o) {
        var $j = jQuery;
        var h = $j.extend({
            }, o);
        function f(s){ return $j('#'+h.id+'_'+s); }
        var countries = BR.room.countries;
        if (countries.length>0) {
            var sel=f('country');
            for(var i=0; i<countries.length; i++) {
                sel.append('<option value="+'+countries[i].code+'">'+countries[i].name+'</option>');
                }
            sel.prop('disabled',false).change(function (){
                var prefix = f('country').val();
                f('prefix').val(prefix);
                });
            f('number').prop('disabled', false);
            }
        f('number').data('cs_load',function(full_number){
            if (full_number==null)
                full_number='';
//console.log(full_number);
            var phone_number = full_number;
            for(i=2; i<Math.min(5,full_number.length); i++) { // try to match increasing long prefixes in dropdown
                var prefix = full_number.substr(0,i);
                f('country').attr('value',prefix);
                prefix = f('country').attr('value');
/*
    -- this actually doesn't work ...
                f('country').val(prefix);
                prefix = f('country').val();
*/
                if (prefix.length>0) {
                    f('prefix').val(prefix);
                    f('country').trigger('change');
                    phone_number = full_number.substr(i);
                    break;
                    }
                }
            f('number').val(phone_number);
            if (phone_number===full_number) // not changed
                f('country').val('');       // reset country to 'select'
            });
        },

    dashboard_add_guests: function(o) {
        var $j = jQuery;
        var h = $j.extend({
            }, o);
        function r(s){ return $j(h.root).find(s); }
        function f(s){ return $j('#'+h.id+'_'+s); }
        f('call').button();
        function full_name(user_id) {
            var u = BRDashboard.user_map[user_id];
            if (u.name) {
                if (u.last_name) return u.name + ' ' + u.last_name;
                else return u.name;
                }
            else if (u.last_name)
                return u.last_name;
            return '';
            }
        if (h.guests) {
            var app = '';
            for(var id in BRDashboard.invitees)
                //app += '<option value="' + id + '">' + BRDashboard.invitees[id].full_name + '</option>';
                app += '<option value="' + id + '">' + full_name(BRDashboard.invitees[id].user_id) + '</option>';
            app.length && $j(h.guests).append(app);
            BRDashboard.subscribe(function(o){
                var option = $j(h.guests+" option[value='"+o.id+"']");
                switch(o.command) {
                    case 'mod':
                        if (option.length)
                            //option.text = o.data.full_name;
                            option.text = full_name(o.data.user_id);
                        else
                            //$j(h.guests).append('<option value="' + o.id + '">' + o.data.full_name + '</option>');
                            $j(h.guests).append('<option value="' + o.id + '">' + full_name(o.data.user_id) + '</option>');
                        break;
                    case 'del':
                        option.remove();
                    }
                },'invitee');
            }

        // --- chained requests section
/* Tokens no longer used ... ref to comment with 'TT' in them ...
        var token = null;
        var fetching_token = false;
        function st(msg) { f('status').text(msg?msg:''); }
        function precreate_token(chain) {
            fetching_token = true;
            st('fetching token');
            BRInvitees.aj("/invitations/add_guest.js", {invitation:{conference_id:BR.room.context.conference_id}, user:{}, auth: BR.room.context.authen}, function(data, textStatus, jqXHR){
                st(null);
                if (textStatus=='success') {
                    token = eval(data)[0].invitation.token;
                    if (chain)
                        do_chain();
                    }
                fetching_token = false;
                });
            }
*/
        var pin = null;
        var fetching_pin = false;
        function get_pin() {
            fetching_pin = true;
            $j(h.call).val('Adding participant...').prop('disabled',true);
            st('fetching pin');
            var full_number = f('prefix').val()+f('number').val();
//            var fs_number = full_number.replace(/^\+1/,'1').replace(/^\+/,'011');
            var fn = f('first_name').val();
            var ln = f('last_name').val();
            var full_name = fn + ' ' + ln;
            BRInvitees.aj("/invitations/add_guest.js", {invitation:{role:null,conference_id:BR.room.context.conference_id,token:token}, user:{name:f('first_name').val(),last_name:f('last_name').val(),phone:full_number}, auth: BR.room.context.authen}, function(data, textStatus, jqXHR){
                st(null);
                if (textStatus=='success') {
                    var invitation = eval(data)[0].invitation;
                    pin = invitation.pin;
                    $j.extend(invitation,{name:fn,last_name:ln,full_name:full_name,phone:full_number});
/*                    BRDashboard.fire({type:'invitee',command:'mod',pin:invitation.pin,user_id:invitation.user_id,data:invitation}); -- now happens via binlog */
                    if (pin)
                        do_chain();
                    }
                $j(h.call).val('Call').prop('disabled',true);
                fetching_pin = false;
//TT                token = null;   // that token has been used
                });
            }
        var calling = false;
        function do_chain() {
            if (calling) return;
            if (pin) {
                // start the call...
                // close the window ... ???
                var full_number = f('prefix').val()+f('number').val();
                BRCommands.fsDialout(pin,full_number,'Babelroom',BRUtils.makeDialToken());
                return;
                }
            if (fetching_pin) return;
/* TT */    return get_pin();
/* TT
            if (token) {
                // fetch pin
                return get_pin();
                }
            if (fetching_token) return;
            // fetch token
            precreate_token(true); */
            }
//TT        precreate_token(false); // -- later
        // --- end chained requests section
        function set_record(rec) {
            if (rec.new_guest) {
                f("first_name").val('').prop('disabled', false);
                f("last_name").val('').prop('disabled', false);
                f("number").data('cs_load')('');
                }
            else {
                f("first_name").val(BRDashboard.user_map[rec.user_id].name).prop('disabled',true);
                f("last_name").val(BRDashboard.user_map[rec.user_id].last_name).prop('disabled',true);
                f("number").data('cs_load')(BRDashboard.user_map[rec.user_id].phone);
                }
            //f("number").data('cs_load')(BRDashboard.user_map[rec.user_id].phone);
            if (BR.room.context.is_host)
                f("pin").text(rec.pin?rec.pin:'');
            else
                f("pin").text("<only viewable by hosts>");
            }
        h.guests && $j(h.guests)
            .change(function(evt){
            var pin = r(":selected").val();
            if (pin!=-1)
                set_record(BRDashboard.invitees[pin]);
            else
                set_record({new_guest:true});
            });
        this.dashboard_phone_fieldset(h);
        h.call && $j(h.call)
            .click(function(evt){
                if (!BR.room.context.is_host) {
                    alert("This host-only feature is shown for demonstration purposes only\n\nOnly hosts may initiate outbound calls to add participants");
                    return;
                    }
                pin = f('pin').text();
                do_chain();
            });
        $j(h.root).find('input, textarea').placeholder();
        if(!BRUtils.hasPlaceholderSupport()){
            $j(h.root).placeholder({blankSubmit:true});
            $j('input[autofocus=true]').focus(); 
            }
        return;
    }
}

