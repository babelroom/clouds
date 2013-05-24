var BRUtils = {
    eaS: null,

    hasPlaceholderSupport: function() {
        var i = document.createElement('input');
        return 'placeholder' in i;
        },

    ass: function(assertion) {
        },

    aq: function(action,args,done) {
        BR.api.v1._aq({ act: action, args: args, auth: BR.room.context.authen }, function(e,d){
            if (e) done(e, "error");
            //else done(JSON.stringify(d) /* bit of a hack -- TMP TODO -- not needed TG */, "success");
            else done(d, "success");
            });
/*
        var result = jQuery.ajax({
            url: BR.api.v1.get_host('api') + "/api/v1/aq",
            type: "POST",
/*            contentType: 'application/json; charset=UTF-8', -- leave it urlencoded *./
            data: { act: action, args: args, auth: BR.room.context.authen },
            dataType: 'json',
            xhrFields: { withCredentials: true },
            success: done,
            error: function (jqXHR, textStatus, errorThrown) { done(errorThrown, textStatus, jqXHR); }
            //error: function (jqXHR, textStatus, errorThrown) { console.log(jqXHR, textStatus, errorThrown); done(errorThrown, textStatus, jqXHR); }
            });
*/
        },

    conferencePath: function() {
        if (BR && BR.room && BR.room.context) {
            if (BR.room.context.conference_uri)
                return '/'+BR.room.context.conference_uri;
            else  if (BR.room.context.conference_id)
                return '/i/'+BR.room.context.conference_id;
            }
        if (/^(?:http|https):\/\/(?:[^\/]+)(\/[^\?|#]*)\??.*$/.exec(document.URL))
            return RegExp.$1;
        return null;
        },

    _makeToken: function(len) {
        var tokenChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        var token = '';
        for(var i=0; i<len; i++)
            token += tokenChars.charAt(Math.floor(Math.random() * tokenChars.length));
        return token;
        },

    makeDialToken: function() {
        return BRUtils._makeToken(16) + new Date().getTime().toString();
        },

    waitForPin: function(user_id, token, timeout, fn) {
        function checkPin(o) {
            if (o.user_id==/*intentional*/user_id)
                done(o.pin);
            }
        function done(pin) {
            BRDashboard.unsubscribe(checkPin);
            fn(pin);
            }
        function checkForCancel(o) {
            if (o.token===token && o.state==='cancelled')
                done(0);
            }
        setTimeout(function(){done(0);}, timeout);
        BRDashboard.subscribe(checkPin, 'pin');
        BRDashboard.subscribe(checkForCancel, 'dialer');
        },

    log: function() {
        if (console && console.log)
            /* TMP TODO -- make this work, as console.log: http://stackoverflow.com/questions/9521921/why-does-console-log-apply-throw-an-illegal-invocation-error */
            //console.log.apply(null, [1,2]);
            console.log([arguments]);
        },

    openConsoleWindow: function() {
        }

/*    openConsoleWindow: function() {
        var theme = 'cs_workspace';
        var id = Application.getNewId();
        var win = new Window(id, {
            className: theme,
            width:400,
            height:200,
            title: "Console",
            recenterAuto: false,
            showEffect: Element.show,
            hideEffect: Element.hide,
            onResize: function(win) {
                var dims = win.getSize();
                $(win.getId() + '_console').style.width = dims.width;
                $(win.getId() + '_console').style.height = dims.height;
                }
            });
        Application.constrain(win);
        win.getContent().innerHTML= '<textarea id="' + id + '_console" class="console" style="width: 400px; height: 200px;" disabled></textarea>';
        win.showCenter(false);
        win.dispatchCh = 'L';
        function msg(str) {
            $(id + '_console').value += str + "\r\n";
            $(id + '_console').scrollTop = $(id + '_console').scrollHeight;
            }
        win.dispatchFn = msg;
        function cb(data) {
            msg(data.str);
            }
        BRDashboard.subscribe(cb,'log');
        win.setCloseCallback(function(){
            BRDashboard.unsubscribe(cb);
            return true;
            });
        win.resetFn = function() {
            $(id + '_console').innerHTML = '';
            };
        Application.replayData(win);
        },
*/
}

