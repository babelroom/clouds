
var crypto = require('crypto')

var CryptUtils = function(config) {
    this.secret = config.secret;
}

function do_crypt(val, secret, enc)
{
    key = secret.slice(16,32);
    iv = secret.slice(48,64);
    var cipher = enc ? crypto.createCipheriv('aes-128-cfb',key,iv) : crypto.createDecipheriv('aes-128-cfb',key,iv);
    var result;
    result = cipher.update(val, 'hex', 'ascii') + cipher.final('ascii');
    return result;
}

CryptUtils.prototype = {
    encrypt: function(val) {
        return do_crypt(val, this.secret, true);
    },
    
    decrypt: function(val) {
        return do_crypt(val, this.secret, false);
    }
}

module.exports = CryptUtils;

