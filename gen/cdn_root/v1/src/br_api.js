(function() {
    /* --- */
    if (typeof window.BR == "undefined")
        window.BR = {};
})();


(function() {
    var _xhr_func = null;

    function XHR() {
        this.options = null;
        }

/*
    function _xhrobj() {
        if (typeof(XMLHttpRequest)==="undefined")
            XMLHttpRequest = function () {
                try { return new XDomainRequest(); }
                    catch (e) {}
                try { return new ActiveXObject("Msxml2.XMLHTTP.6.0"); }
                    catch (e) {}
                try { return new ActiveXObject("Msxml2.XMLHTTP.3.0"); }
                    catch (e) {}
                try { return new ActiveXObject("Microsoft.XMLHTTP"); }
                    catch (e) {}
                //Microsoft.XMLHTTP points to Msxml2.XMLHTTP and is redundant
                return null;
            }
        else
            return new XMLHttpRequest();
        }
*/
    function _jquery_ajax(verb, url, data, fn) {
        /* ... todo ... */
        }

    function _xhr(verb, url, data, fn) {
        var x = new XMLHttpRequest();
        if (false) {
            if (verb!=='GET' && verb!='POST') {
                x.setRequestHeader('X-HTTP-Method-Override', verb);
                verb = 'POST';
                }
            }
//verb = 'GET';
        if (x===null)
            return fn('No XHR Support');
        try { x.open(verb, url, true); }
        catch (e) {
            fn(e,null);
            }
        x.withCredentials = true;
        if (data)
            x.setRequestHeader('Content-Type', 'application/json');
        x.onreadystatechange = function(data){
            if (x.readyState==4) {
                var r = null;
                if (x.status!=200)
                    return fn('Remote Error');
                try { r = JSON.parse(x.responseText); }
                catch (e)
                    { return fn('Protocol Error'); }
                if (r.error)
                    return fn('Remote Error: '+(r.error.text||''));
                fn(null,r);
                }
            }
        if (data) x.send(JSON.stringify(data));
        else x.send();
        return true;    /* we handled the request, return false to indicate fn() will not be called... */
        }

    function _ms_XDomainRequest_no_cookies(verb, url, data, fn) {
        /*  note:
        No cookies get sent
            some problems (big enough to kill this):
            - can't send cookies
            - or return them    (**deal breaker)
            - can only use GET or POST and can't send custom headers to fake other methods
        */
        var x = new XDomainRequest();
        x.onload = function () {
                var r = null;
                try { r = JSON.parse(x.responseText); }
                catch (e)
                    { return fn('Protocol Error'); }
                fn(null,r);
            }

        x.onerror = function() { fn('Error'); }
        x.onprogress = function() { /*console.log('onprogress',x);*/ }
        x.ontimeout = function() { fn('Timeout'); }
        x.open(verb, url);

        if (data) x.send(JSON.stringify(data));
        else x.send();
        }

    /* figures out which ajax mechanism to use */
    function xhr_func() {
        if (_xhr_func)
            return _xhr_func;
        _xhr_func = function(a,b,c,fn){console.log('No XHR');fn('No XHR Support');}
        if (false) ;
            /* jquery ajax */
        else if (window.XDomainRequest)
            _xhr_func = _ms_XDomainRequest_no_cookies;
        else if (window.XMLHttpRequest)
            _xhr_func = _xhr;
        return _xhr_func;
        }

    XHR.prototype.init = function(options) {
        this.options = options;
        return this;
        }

    XHR.prototype.request = function(verb, url, data, fn) {
        return xhr_func().call(this, verb, url, data, fn);
        }

    /* --- */
    window.BR.XHR = function(){return new XHR();}
})();


(function(){
    /* we can try (and actually do) determine the site this script was downloaded from */
    var scripts = document.getElementsByTagName("script"),
        src_of_this_src = scripts[scripts.length-1].src;
    /* static data */
    var countries = [
        { code: 1,      name: 'United States' },
        { code: 212,    name: 'Morocco' },
        { code: 33,     name: 'France' },
        { code: 34,     name: 'Spain' },
        { code: 351,    name: 'Portugal' },
        { code: 353,    name: 'Ireland' },
        { code: 39,     name: 'Italy' },
        { code: 44,     name: 'United Kingdom' },
        { code: 49,     name: 'Germany' }
        ];
    var config_map = {
        dev: {
            hosts: {
                api:    '//api-dev.babelroom.com',
                my:     '//my-dev.babelroom.com',
                myapi:  '//myapi-dev.babelroom.com', // TODO -- will depreciate
                live:   '//live-dev.babelroom.com',
                page:   '//dev.babelroom.com',
                cdn:    '//cdn-dev.babelroom.com',
                home:   '//staging.babelroom.com',
                //video:  '//video-dev.babelroom.com:1936'
                video:  '//video.babelroom.com:1936'
                }
            },
        staging: {
            hosts: {
                api:    '//api-staging.babelroom.com',
                my:     '//my-staging.babelroom.com',
                myapi:  '//myapi-staging.babelroom.com', // TODO -- will depreciate
                live:   '//live-staging.babelroom.com',
                page:   '//rooms-staging.babelroom.com',
                cdn:    '//cdn-staging.babelroom.com',
                home:   '//staging.babelroom.com',
                //video:  '//video-dev.babelroom.com:1936'
                video:  '//video.babelroom.com:1936'
                }
            },
        prod: {
            hosts: {
                api:    '//api.babelroom.com',
                my:     '//my.babelroom.com',
                myapi:  '//myapi.babelroom.com', // TODO -- will depreciate
                live:   '//live.babelroom.com',
                page:   '//bblr.co',
                cdn:    '//cdn.babelroom.com',
                home:   '//babelroom.com',
                video:  '//video.babelroom.com:1936'
                }
            }
        };

    function API() {
        this.options = null;
//        this.config = null;
        this.hosts = null;
        this.stream_channel = undefined;
        this.xhr_channel = undefined;
        }

    /* --- utils --- */
    function _open_stream(fn) {
        if (typeof(this.stream_channel)!=="undefined")
            return fn('Stream already opened');
        if (!this.options.streamFactory)
            return fn('No stream factory');
        this.stream_channel = this.options.streamFactory();
        if (!this.stream_channel)
            return fn('Failed top open stream');
        this.stream_channel.connect(_get_host.call(this, 'live'),fn);
        }

    function _non_stream_call(verb, path, data, fn) {
        if (typeof(this.xhr_channel)==="undefined")
            this.xhr_channel = BR.XHR();
        if (!this.xhr_channel)
            return fn('No communication channel');
        return this.xhr_channel.request(verb, _get_host.call(this, 'api')+path, data, fn);
        }

    function _form_call(verb, path, data) { /* an error will be raised if _dynamic_form_id has not been set */
        // like this: <form id="_ie_dynform" style="display: none;" action="//api-dev.babelroom.com/api/v1/_dynform"></form>
        // and this: a.init({query_string:window.location.search, _dynamic_form_id:'_ie_dynform'});
        var frm = document.getElementById(this.options._dynamic_form_id);
        while (frm.hasChildNodes()) {   /* not really necessary if requests result in redirect, but cleaner, particularly in cases of error */
            frm.removeChild(frm.lastChild);
            }
        frm.setAttribute("method", 'POST');
/*        frm.setAttribute("action",host+path); .. can't create or changed dynamically by IE for security */
/*        frm.setAttribute("target", 'example_parent');   .. allowed? */
        function add_input(name, type, value) {
            var e = document.createElement("input");
            e.setAttribute("name",name);
            e.setAttribute("type",type);
            e.setAttribute("value",value);
            frm.appendChild(e);
            }
        add_input('_dynform_method', 'hidden', verb);
        add_input('_dynform_path', 'hidden', path);
        for(var i in data)
            if (data.hasOwnProperty(i) && typeof(data[i])==="string")
                add_input(i, 'text', data[i]);
        frm.submit();
        }

    function _canonify_cookie_call_options(options) {
        options = options || {};
        if (!options.success_url) options.success_url = window.location.href;
        if (!options.failure_url) options.failure_url = options.success_url;
        if (!options.fnerror) options.fnerror = function(e){};  /* depreciate this in order to keep semantics simpler ... */
        return options;
        }

    function _cookie_call(verb, path, data, options, fn) {
        if (!data)
            data = {};
        data._success_url = options.success_url;
        data._failure_url = options.failure_url;
        //return _non_stream_call.call(this, verb, path, data, fn); -- later: this is the correct alternative 
        return _form_call.call(this, verb, path, data);
        }

    function _cookie_call_response(is_error, e, options) {
        if (!is_error) {
            if (options.fnerror)
                fnerror(e);
            else
                window.location.href = options.failure_url;
            }
        else
            window.location.href = options.success_url;
        }

    function _call(verb, path, data, fn) {
        /* if we have a stream then marshall the call over the stream, thereby dodging xhr XSS hell */
        if (/*false &&*/ this.stream_channel) {
            this.stream_channel.api_call({verb: verb, path: path, /*cookie: document.cookie,*/ data: data},function(e,d){
                return fn(e, (!e&&d)?(JSON.parse(d)):null);
                });
            return ;
            }
        return _non_stream_call.call(this, verb, path, data, fn);
        }

    function _parseQueryString(qs) {
        var dict   = {},
            match,
            pl     = /\+/g,  // Regex for replacing addition symbol with a space
            search = /([^&=]+)=?([^&]*)/g,
            decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); };
        while (match = search.exec(qs.substring(1)))
            dict[decode(match[1])] = decode(match[2]);
        return dict;
        }

    function _orm_shallow_copy(obj) {   /* fold this in use if not used in more than 1 place */
        var new_obj = {};
        for(var i in obj)
            if (obj.hasOwnProperty(i) && i[0]!='_')
            //if (obj.hasOwnProperty(i))
                new_obj[i] = obj[i]
        return new_obj;
        }

    function _get_host(name) {
        return this.hosts[name];
        }

    function _addStreamCredential(path, token, fn) {
        /* connect stream */
        var _this = this;
        function stream_authenticate() {
            _this.stream_channel.add_conference_credential(path, token, function(e,d){
//console.log(e,d);
                if (e || !d) return fn(e || 'unexpected response');
                fn(e,d);
                });
            }
        if (this.stream_channel)
            stream_authenticate();
        else return _open_stream.call(this, function(error) {
                if (error) return fn(error);
                stream_authenticate();
            });
        }

    /* model stuff, in flux ... */
    function _model(model, arg, fn) {
        var id = 0;
        var qs = '';
        switch(typeof(arg)) {
            case 'number': id = arg; break
            case 'object': id = arg.id;
                if (arg.columns) qs = '?c='+arg.columns.join(',');
                break;
            default:
                return fn('bad args',null);
            }
        return _call.call(this, 'GET', '/api/v1/'+model+'/'+id, null, function(e,d){
            if (d && d.data) {          /* this is one way of doing this, not sure it is the right way yet */
                var copy = _orm_shallow_copy(d.data);
                copy._ = {id: id, model: model, orig: d.data}
                return fn(e,copy);
                }
            else
                return fn(e?e:'unexpected enveloped format',null);
            });
        }
/* where is this used? -- depreciate
    function _save(model, id, arg, fn) {
// TODO --- what about when PUT isn't supported???, i.e. POST??? tmp.
        return _call.call(this, 'PUT', '/api/v1/'+model+'/'+id, arg, fn);
        }
*/
    function _update(obj, fn) {
//console.log('obj',obj);
        if (typeof(obj)!=="object" || !obj._ || !obj._.id || !obj._.model || !obj._.orig)
            return fn('corrupt API record',null);
//console.log('obj',obj);
        var to_save = {};
        var found = false;
        for(var i in obj)
            if (obj.hasOwnProperty(i) && i[0]!='_' && obj._.orig[i]!==obj[i]) {
                to_save[i] = obj[i];
                found = true;
                }
//console.log('to_save',to_save);
//console.log('found',found);
        if (!found)
            return fn(null,{});
        else
            return _call.call(this, 'PUT', '/api/v1/'+obj._.model+'/'+obj._.id, to_save, function(e,d){
                if (!e && d) obj._.orig = _orm_shallow_copy(obj);
                fn(e,d);
                });
        }

    /* init */
    API.prototype.init = function(args) {
        /* this next line is practically a work of art .. but unnecessary here
        var subdomain = src_of_this_src.match(/^(?:http:|https:)\/\/([a-z0-9]+(?:-[a-z0-9]+)*)(\.[a-z0-9]+(-[a-z0-9]+)*)/i); */
        var subdomain = src_of_this_src.match(/^(?:http:|https:)\/\/([a-z0-9]+(?:-[a-z0-9]+)*)\.babelroom.com\//i);
        var _config = (subdomain && subdomain[1].match('dev')) ? config_map.dev : config_map.prod;
        var hosts = null;
        this.options = {
            /* defaults */
            streamFactory: window.BR.SIO
            }
        if (typeof(args)==='object') {
            if (typeof(args['query_string'])==='string') {
                var d = _parseQueryString(args['query_string']);
                for(v in d) 
                    if (d.hasOwnProperty(v))
                        args[v] = d[v];
                /* then remove query string */
                delete args['query_string'];
                }
            for(var key in args)
                if (args.hasOwnProperty(key)) {
                    var val = args[key];
                    switch(key) {
                        case 'env': _config = config_map[val]; break;
                        case 'hosts': hosts = val; break;  /* either a hash of alternate hosts, or a string specifying a single host to override them all */
                        default:
                            this.options[key] = val;
                    }
                }
            }
        this.hosts = {};
        for(var i in _config.hosts)
            if (_config.hosts.hasOwnProperty(i))
                this.hosts[i] = (hosts!==null) ? (typeof(hosts)==='object'? (typeof(hosts[i])!=="undefined"?hosts[i]:_config.hosts[i]) :hosts) : _config.hosts[i];
        };

    /* return static data */
    API.prototype.get_host = function(name) { return _get_host.call(this, name); }
    API.prototype.get_countries = function(fn) {
        fn(null,countries);
        return this;
        };

    /* stream */
    API.prototype.stream = function(get_or_set_stream) {
        if (typeof(get_or_set_stream)==="undefined") /* get */
            return this.stream_channel;
        this.stream_channel = get_or_set_stream;
        }
    
    API.prototype.addStreamCredential = function(path, token, fn) {
        return _addStreamCredential.call(this, path, token, fn);
        }



    /* API calls which may set cookies and redirect */
    API.prototype.login = function(data, options) {
        options = _canonify_cookie_call_options(options);
        return _cookie_call.call(this, 'POST', '/api/v1/login', data, options, function(e,d){
            _cookie_call_response(e || !d, e, options);     /* intentional: !e == login failed, else error logging in */
            });
        }

    API.prototype.logout = function(options) {
        options = _canonify_cookie_call_options(options);
        return _cookie_call.call(this, 'DELETE', '/api/v1/login', null, options, function(e,d){
            _cookie_call_response(e, e, options);
            });
        }

    API.prototype.addSelf = function(path, data, options) {
        options = _canonify_cookie_call_options(options);
        return _cookie_call.call(this, 'POST', '/api/v1/add_self'+path, data, options, function(e,d){
            _cookie_call_response(e || !d, e || 'Missing response data', options);  /* should always return something in d on success */
            });
        }



    /* regular API calls */
    API.prototype.currentUser = function(fn) {
        return _call.call(this, 'GET', '/api/v1/login', null, function(e,d){fn(e,d?d.user:null);});
        }

    API.prototype.addParticipant = function(path, data, fn) {
        //return _call.call(this, 'POST', '/api/v1/add_participant'+path, data, function(e,d){fn(e,d?d.user:null);});
        return _call.call(this, 'POST', '/api/v1/add_participant'+path, data, fn);
        }

    API.prototype.users = function(arg,fn) { return _model.call(this, "users", arg, fn); }             /* still figuring this */
    API.prototype.update = function(obj,fn) { return _update.call(this, obj, fn); }
    API.prototype.conferences = function(arg,fn) { return _model.call(this, "conferences", arg, fn); }

    API.prototype._aq = function(data, fn) {            /* 2depreciate */
        return _call.call(this, 'POST', '/api/v1/_aq', data, fn);
        }

    /* --- */
    if (typeof window.BR.api == "undefined")
        window.BR.api = {};
    window.BR.api.v1 = new API();
})();

