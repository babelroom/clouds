
var crypto = require('crypto')

var CryptUtils = function(config) {
    this.secret = config.secret;
}

function do_crypt(val, secret, enc)
{
    key = secret.slice(16,32);
    iv = secret.slice(48,64);
    var cipher, result;
    if (enc) {
        cipher = crypto.createCipheriv('aes-128-cfb',key,iv);
        result = cipher.update(val, 'ascii', 'hex') + cipher.final('hex');
        }
    else {
        cipher = crypto.createDecipheriv('aes-128-cfb',key,iv);
        result = cipher.update(val, 'hex', 'ascii') + cipher.final('ascii');
        }
    return result;
}

CryptUtils.prototype = {
    encrypt: function(val) {
/*
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
    },

    md5: function(val) {
        return crypto.createHash('md5').update(this.secret.slice(0,16)+val+this.secret.slice(32,48)).digest("base64");
    }
}

module.exports = CryptUtils;

