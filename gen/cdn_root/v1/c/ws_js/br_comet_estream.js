
/*
** This file is redanted for historical / references purposes
*/

var msieMemoryFile = null;
var doPUT_comet = null;
var longGET_comet = null;
var lg_estream_host = null;

function dispatchData1(data) {
    // data may contain more than 1 message
//console.log('data='+data);
    var consumed_length = 0;
    for(;;) {
        if (data.length < 4)
            return consumed_length;
        var len = parseInt(data.substr(0,4), 10);
//console.log('len='+len);
        if (isNaN(len))
            return -1;
        if (len>(data.length-4)) {
            /* need more data ... */
            return consumed_length;
            }
        BRCommands.dispatchData2(data.substr(4,len));
        data = data.substr(4+len);
        consumed_length += (4+len);
        }
}

function longGET_websocket(other_functions) {
    if ("WebSocket" in window) {
        var surl = "ws://" + BRCommands.estream_host + "/conference/" + BRCommands.cid + '?ld=' + context.connection_salt + '-' + context.user_id;
        try {
            var ws = new WebSocket(surl);
            }
        catch(e) {
            return longGET_try(other_functions);
            }
        ws.onopen = function() {
            //ws.send("message to send");
            }
        ws.onerror = function() {
            //return longGET_try(other_functions);
            }
        ws.onmessage = function (evt) {
            BRCommands.dispatchData2(evt.data);
            };
        ws.onclose = function() { // websocket is closed.
            //BRCommands.updateProgress("Closed");
            return longGET_try(other_functions);
            }
    } else {
        // the browser doesn't support WebSocket.
        //BRCommands.updateProgress("This browser does not support WebSocket");
        return longGET_try(other_functions);
    }
}

function longGET_XHR(other_functions) {
    if (    /MSIE (\d+\.\d+);/.test(navigator.userAgent)            ||
//            (/Firefox[\/\s](\d+\.\d+)/.test(navigator.userAgent)) ... todo ... later
            false
            ){ //test for MSIE x.x;
        // explcitly fail this for IE, it connects OK, but doesn't return data until the connection is closed
        // ditto older firefox's
        return longGET_try(other_functions);
        }
    var offset = 0;
    if (window.XMLHttpRequest) {
        self.xmlHttpReq = new XMLHttpRequest();
    }
    else if (window.ActiveXObject) {
        self.xmlHttpReq = new ActiveXObject("Microsoft.XMLHTTP");
    }
    if (self.xmlHttpReq==null) 
        return longGET_try(other_functions);
    try {
        self.xmlHttpReq.open('GET', lg_estream_host + "/conference/" + BRCommands.cid + "?fmt=1&ld=" + context.connection_salt + '-' + context.user_id, true);
        }
    catch(e) {
        return longGET_try(other_functions);
        }
    self.xmlHttpReq.onreadystatechange = function() {
        switch(self.xmlHttpReq.readyState) {
            case 1:
                BRCommands.updateProgress('1');
                break;
            case 2:
                BRCommands.updateProgress('2');
                break;
            case 3:
                var str = self.xmlHttpReq.responseText.substr(offset);
                var consumed = dispatchData1(str);
                if (consumed>0) 
                    offset += consumed;
                else if (consumed==-1) {
                    self.xmlHttpReq.abort();
                    self.xmlHttpReq = null;
                    }
                /* offset = self.xmlHttpReq.responseText.length; */
                BRCommands.updateProgress('3');
                break;
            case 4:
                BRCommands.updateProgress('4');
       		return longGET_try(other_functions);
                // TODO: connection ended ... re-connect .. (ask user...)
                // --- response is done, restart it! (comment/uncomment at will)
		        // this will automatically reconnect if the event server is reset
                //longGET();
            }
    }
    self.xmlHttpReq.send();
}

function csiframeCB(data)
{
    if (!data.length)
        return;
    data = unescape(data.replace(/\+/g, " "));
    return BRCommands.dispatchData2(data);
}

function longGET_iframe()
{
    var surl = lg_estream_host + "/conference/" + BRCommands.cid + "?fmt=2&ld=" + context.connection_salt + '-' + context.user_id;
    var iframe = document.body.appendChild(document.createElement("iframe"));
    iframe.style.display = "none";
// TODO ... working on this
parent.csiframeCB = function(data) { alert(data); }
    iframe.src = surl;
}

function longGET_IEiframe(transferDoc)
{
    var surl = lg_estream_host + "/conference/" + BRCommands.cid + "?fmt=2&ld=" + context.connection_salt + '-' + context.user_id;
    transferDoc.open();
    transferDoc.write("<html><script>");
    var domainparts = document.domain.split(".");
    transferDoc.write("document.domain=\"" + domainparts[domainparts.length-2] + "." + domainparts[domainparts.length-1] + "\";");
    transferDoc.write("</script></html>");
    transferDoc.parentWindow.csiframeCB = csiframeCB;
    transferDoc.close();
    transferDoc.body.innerHTML = "<iframe src='" + surl + "'></iframe>";

    return;
}

function longGET_IE(other_functions)
{
    try { msieMemoryFile = new ActiveXObject("htmlfile"); }
    catch(e) { }
    if (msieMemoryFile)
        return longGET_IEiframe(msieMemoryFile);
    else
        return longGET_try(other_functions);
}

function longGET_tryProxy(other_functions)
{
    lg_estream_host = '';
    return longGET_try(other_functions);
}

function longGET_endOfTheLine(other_functions)
{
    alert('Unable to establish the long-running connection for event updates. Please contact support staff and communicate the following browser information:\n\n'+navigator.userAgent);
}

function longGET_try(functions)
{
    if (!functions.length)
        return;
    var fn = functions[0];
    functions.splice(0,1);
    return fn(functions);
}

// --------------------------------------------------------------------

function doPUT_xhr(queue,data,fn) {
    var PUTReq = false;
    var self = this;

    if (window.XMLHttpRequest) {
        self.PUTReq = new XMLHttpRequest();
    }
    else if (window.ActiveXObject) {
        self.PUTReq = new ActiveXObject("Microsoft.XMLHTTP");
    }
    self.PUTReq.open('PUT', 'http://' + BRCommands.estream_host + queue, true);
    self.PUTReq.onreadystatechange = function() {
        if (self.PUTReq.readyState == 4) {
            fn();
        }
    }
    self.PUTReq.send(data);
}

function doPUT_IEiframe(queue,data,fn) {
    var surl = "http://" + BRCommands.estream_host + queue + "?p=" + escape(data);
    var transferDoc = new ActiveXObject("htmlfile");
    transferDoc.open();

    transferDoc.write("<html><body><iframe src='" + surl + "'></iframe></body></html>");
    transferDoc.close();

    fn('launched (iframe)');
    transferDoc = null;

    return;
}

// ----------------------------------------------------------------

function longGET()
{
    lg_estream_host = "http://" + BRCommands.estream_host; // direct connection
    var functions2try = [
        longGET_websocket,
        longGET_XHR,
        longGET_IE,
/*
        longGET_tryProxy,
        longGET_XHR,
*/
//        longGET_endOfTheLine -- TODO don't want this message pushed out at end of connection
        ];
    longGET_try(functions2try);
}

function doPUT(queue,data,fn) {
    if (!doPUT_comet) comet_init();
    doPUT_comet(queue,data,fn);
}

function comet_init()
{
    if (longGET_comet) return;  // already initialized

//    if (navigator.userAgent.match(/Chrome/)) -- for ref.
    var desc = '';
    if (/MSIE (\d+\.\d+);/.test(navigator.userAgent)){ //test for MSIE x.x;
        var ieversion=new Number(RegExp.$1) // capture x.x portion and store as a number
        if (ieversion>=9)
            desc = "You're using IE9 or above";
        else if (ieversion>=8)
            desc = "You're using IE8.x";
        else if (ieversion>=7)
            desc = "You're using IE7.x";
        else if (ieversion>=6)
            desc = "You're using IE6.x";
        else if (ieversion>=5)
            desc = "You're using IE5.x";
        doPUT_comet = doPUT_IEiframe;
        longGET_comet = longGET_IE;
        }
    else {
        doPUT_comet = doPUT_xhr;
        }
    longGET_comet = longGET;

    return '';  // no problem
}

function comet_destroy()
{
    if (msieMemoryFile) {
        // help IE garbage collector ditch the comet transaction
        msieMemoryFile = null;
        CollectGarbage();
        }
}

