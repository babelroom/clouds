
var dgram = require('dgram')
    , socket = dgram.createSocket('udp4')

socket.bind();

// http://stackoverflow.com/questions/9242957/node-js-dgram-setbroadcastflag-fails-due-to-ebadf
//socket.setBroadcast(true);
socket.on('listening', function(){
    socket.setBroadcast(true);
});

var UDPSender = function(config) {
    /* currently unused */
}

module.exports = UDPSender;

UDPSender.prototype = {
    send: function(msg) {
        /* create Buffer object every time to this method can run totally asyronchronously */
        var buf = new Buffer(msg);
        socket.send(buf, 0, buf.length, 6668, "255.255.255.255", function(err, bytes){
            });
        }
};

