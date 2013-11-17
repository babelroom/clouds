
var dgram = require('dgram')
    , socket = dgram.createSocket('udp4')

socket.bind();
socket.setBroadcast(true);

var UDPSender = function(config) {
    /* currently unused */
}

module.exports = UDPSender;

UDPSender.prototype = {
    send: function(msg) {
        /* create Buffer object every time to this method can run totally asyronchronously */
        var buf = new Buffer(msg);
        socket.send(buf, 0, buf.length, 6668, "255.255.255.255", function(err, bytes){
            console.log(['UDPSend::send',err,bytes]);   // TODO: remove
            });
        }
};

