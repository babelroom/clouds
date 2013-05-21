
/*
** This is merely an example...
*/
var config = {
    groups: [{
        apps: ['api','live'],
        servers: [{
                protocol: 'https',
                bindaddr: '192.168.66.139',
                bindport: 443,
//                options: {key: './dev_certs/privatekey.pem', cert: './dev_certs/certificate.pem'},
                options: {key: '/home/br/gits/netops/clouds/certs/wd.key', cert: '/home/br/gits/netops/clouds/certs/wd_bundle.crt'},
            },{
                protocol: 'http',
                bindaddr: '192.168.66.139',
                bindport: 80,
            }],
        estream: {
            hostname: '127.0.0.1',
            port: 8888,
            },
        api: {
            hostname: '192.168.66.139',
            port: 80,
            },
        session_manager: {
            key: 'brv1_dev',
            domain: '.babelroom.com',
            },
        mysql: {
            poolsize: 20,
            host: '127.0.0.1',
            user: 'root',
            database: 'my',
            password: '',
            },
        secret: 'd38f7f8c6fe4c5fa3367de334d6a67e8f322ac9b14c7bf0469a64037ef67589661be8620bae182899b5e48d3b3f9e0d8ce95be967db1485e05674ff2b4e7e1c6',
        }
        ]
}
 
module.exports = config;

