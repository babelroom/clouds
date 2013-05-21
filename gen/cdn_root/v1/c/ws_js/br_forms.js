var BRForms = {

    hasPlaceholderSupport: function() {
        var i = document.createElement('input');
        return 'placeholder' in i;
        },

    aq: function(h,action,args,done) {
        jQuery.ajax({
            url: "/aq.js",
            type: "POST",
            data: { act: action, args: args, auth: h.authen },
            success: done,
            error: function (jqXHR, textStatus, errorThrown) { done(errorThrown, textStatus, jqXHR); }
            });
        },

    password_matches: function(h,field,blur,other) {
        if (!field.value) {
            if (!blur)
                h.errInfo(field,'Required');
            return false;
            }
        if (field.value && field.value!=other.value) {
            h.errInfo(field,'Passwords do not match');
            return false;
            }
        else {
            h.okInfo(field,'OK');
            return true;
            }
        },

    non_empty: function(h,field,blur) {
        if (!field.value) {
            if (!blur)
                h.errInfo(field,'Required');
            return false;
            }
        h.okInfo(field,'OK');
        return true;
        },

    min_len: function(h,field,blur,req_len) {
        if (!field.value) {
            if (!blur)
                h.errInfo(field,'Required');
            return false;
            }
        if (field.value && field.value.length>=req_len) {
            h.okInfo(field,'OK');
            return true;
            }
        else {
            //h.errInfo(field,'Too short (minimum '+req_len.toString()+')');
            h.errInfo(field,'Too short');
            return false;
            }
        },

    invalid_room_url: function(url) {
        return !url.match(/^([A-Za-z0-9_\-\.]){3,128}$/);
        },

    room_url: function(h,field,blur) {
        if (!field.value) {
            if (!blur)
                h.errInfo(field,'Required');
            return false;
            }
        if (!field.value || this.invalid_room_url(field.value)) {
            h.errInfo(field,'Invalid URL');    // TODO address
            return false;
            }
        if (!blur)  /* summary answer based on last result ... */
            return $(field).data('cs_invalid')===true ? false : true;
//        this.aq(h,15, {ah:[field.value]}, function (data, textStatus, jqXHR) {
//        this.aq(h,15, {ah:[field.value,field.value]}, function (data, textStatus, jqXHR) {
        this.aq(h,15, {ah:{uri:field.value}}, function (data, textStatus, jqXHR) {
            if (textStatus=='success') {
                var result = eval(data);
                var exists = (result.length>0);
                if (result!=null) {
                    if (exists) {
                        h.errInfo(field, 'Taken, please select another URL');
                        $(field).data('cs_invalid',true);
                        }
                    else {
                        h.okInfo(field,'Available');
                        }
                    }
                }
            });
        },

    invalid_email: function(email) {
        return !email.match(/^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$/);
        },

    em: function(h,field,blur,should_exist) {
        if (!field.value) {
            if (!blur)
                h.errInfo(field,'Required');
            return false;
            }
        if (!field.value || this.invalid_email(field.value)) {
            h.errInfo(field,'Not a valid email');
            return false;
            }
        if (!blur)  /* summary answer based on last result ... */
            return $(field).data('cs_invalid')===true ? false : true;
        this.aq(h,6, {ah:[field.value]}, function (data, textStatus, jqXHR) {
            if (textStatus=='success') {
                var result = eval(data);
                var exists = (result.length>0);
                if (result!=null) {
                    if (exists === should_exist) {
                        h.okInfo(field,'OK');
                        }
                    else {
                        h.errInfo(field, exists ? 'Already registered' : 'Not a registered email');
                        $(field).data('cs_invalid',true);
                        }
                    }

                }
            });
        },

    subscribe: function(o) {
        var foa = function(field){
            var nd = $(field).parent().parent().find('#'+field.id+'_msg');
            if (nd.length) return nd;
            nd = $('<span id="'+field.id+'_msg" class="msg"></span>').appendTo($(field).parent());
            return nd;
            }
        var err_html = function(msg) { return '<span class="val_err">'+msg+'</span>'; }
        var ok_html = function(msg) { return ''; }
        function ae(field)   { $(field).addClass('fieldWithErrors'); $('#'+field.id+'_label').addClass('fieldWithErrors'); }
        function re(field)   { $(field).removeClass('fieldWithErrors'); $('#'+field.id+'_label').removeClass('fieldWithErrors'); }
        var h = $.extend({
            clearInfo: function(field){ foa(field).html(''); $(field).data('cs_invalid',false); },
            errInfo: function(field,msg){ foa(field).html(err_html(msg)).addClass('error'); ae(field); },
            //errInfo: function(field,msg){ foa(field).text(err_html(msg)).addClass('error'); },
            findOrAppend: foa,
            okInfo: function(field,msg){ foa(field).html(ok_html(msg)).removeClass('error'); re(field); },
            }, o);
        var tests = {};
        if (h.room_url) tests[h.room_url]=function(dom,blur){ return BRForms.room_url(h,dom,blur);}
        if (h.first_name) tests[h.first_name]=function(dom,blur){ return BRForms.non_empty(h,dom,blur);}
        if (h.last_name) tests[h.last_name]=function(dom,blur){ return BRForms.non_empty(h,dom,blur);}
        if (h.email) tests[h.email]=function(dom,blur){ return BRForms.em(h,dom,blur,false);}
        if (h.password) tests[h.password]=function(dom,blur){ return BRForms.min_len(h,dom,blur,4);}
        if (h.password_confirmation) tests[h.password_confirmation]=function(dom,blur){ return BRForms.password_matches(h,dom,blur,$(h.password).get(0));}
        h.room_url && $(h.room_url)
            .focus(function(evt){ h.clearInfo(this); })
            .blur(function(evt){ tests[h.room_url](evt.target,true); })
            ;
        h.first_name && $(h.first_name)
            .focus(function(evt){ h.clearInfo(this); })
            .blur(function(evt){ tests[h.first_name](evt.target,true); })
            ;
        h.last_name && $(h.last_name)
            .focus(function(evt){ h.clearInfo(this); })
            .blur(function(evt){ tests[h.first_name](evt.target,true); })
            ;
        h.email && $(h.email)
            .focus(function(evt){ h.clearInfo(evt.target); })
            .blur(function(evt){ tests[h.email](evt.target,true); })
            ;
        h.password && $(h.password)
            .focus(function(evt){ h.clearInfo(evt.target); })
            .blur(function(evt){ tests[h.password](evt.target,true); })
            .pstrength({
                displayMin: false,
                minChar: 4
                //, addTo: jQuery('#signup_password_info') -- not needed, and messes with formatting (height)
                });
        h.password_confirmation && $(h.password_confirmation)
            .focus(function(evt){ h.clearInfo(evt.target); })
            .blur(function(evt){ tests[h.password_confirmation](evt.target,true); })
            ;
        h.form && $(h.form)
            .submit(function(evt){
                var canProceed = true;
                $.each(tests, function(index,value) {
                    if (!value($(index).get(0),false))
                        canProceed = false;
                    });
                return canProceed;
                });
        if (h.placeholders==undefined || h.placeholders) {  /* default, true */
            $(h.form).find('input, textarea').placeholder();
            if(!this.hasPlaceholderSupport()){
                $(h.form).placeholder({blankSubmit:true});
                }
            }
        else {
            //h.form && $(h.form).find('label').css('display','block');
            //h.form && $(h.form).find('label').css('display','inline');
            h.form && $(h.form).find('input').removeAttr('placeholder');
            }
        $('input[autofocus=true]').focus(); 
    },

    login: function(o) {
        var foa = function(field){
            var nd = $(field).parent().find('#'+field.id+'_info');
            if (nd.length) return nd;
            nd = $('<label id="'+field.id+'_info"></label>').appendTo($(field).parent());
            return nd;
            }
        var err_html = function(msg) { return '<img src="'+BR.api.v1.get_host('cdn')+'/v1/c/img/x-issue.png" alt="" border="0"> <span class="val_err">'+msg+'</span>'; }
        var ok_html = function(msg) { return '<img src="'+BR.api.v1.get_host('cdn')+'/v1/c/img/check.png" alt="" border="0">'+msg; }
        var h = $.extend({
            clearInfo: function(field){ foa(field).html(''); $(field).data('cs_invalid',false); },
            errInfo: function(field,msg){ foa(field).html(err_html(msg)).addClass('error'); },
            okInfo: function(field,msg){ foa(field).html(ok_html(msg)).removeClass('error'); },
            }, o);
        var tests = {};
        if (h.email) tests[h.email]=function(dom,blur){ return BRForms.em(h,dom,blur,true);}
        if (h.password) tests[h.password]=function(dom,blur){ return BRForms.min_len(h,dom,blur,4);}
        h.email && $(h.email)
            .focus(function(evt){ h.clearInfo(evt.target); })
            .blur(function(evt){ tests[h.email](evt.target,true); })
            ;
        h.password && $(h.password)
            .focus(function(evt){ h.clearInfo(evt.target); })
            .blur(function(evt){ tests[h.password](evt.target,true); })
            ;
        h.form && $(h.form)
            .submit(function(evt){
                var canProceed = true;
                $.each(tests, function(index,value) {
                    if (!value($(index).get(0),false))
                        canProceed = false;
                    });
                return canProceed;
                });
        $(h.form).find('input, textarea').placeholder();
        if(!this.hasPlaceholderSupport()){
            $(h.form).placeholder({blankSubmit:true});
            $('input[autofocus=true]').focus(); 
            }
    }
}

