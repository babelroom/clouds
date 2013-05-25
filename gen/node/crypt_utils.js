
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
/*
 frankly couldn't get this to work properly in the time available
        var missing = 32-(val.length);
console.log(1,val);
console.log(2,missing);
        if (missing>0) {
            //val += crypto.randomBytes(Math.floor(missing/2)+1).toString(16);
            buf = crypto.randomBytes(Math.floor(missing/2)+1);
            val += buf.toString('hex');
            }
        val = val.substr(0,32);
console.log(3,val);
console.log('   01234567890123456789012345678901234567890');
console.log(4,val);
*/
        return do_crypt(val, this.secret, true);
    },
    
    decrypt: function(val) {
        return do_crypt(val, this.secret, false);
    }
}

module.exports = CryptUtils;

