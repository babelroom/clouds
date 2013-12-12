#!/bin/sh

echo 'fail2ban...'

test -x /usr/bin/fail2ban-server && test -f /etc/fail2ban/filter.d/freeswitch-dos.conf && echo 'Already installed!' && exit 0;

cd $HOME
test -d src || mkdir src
cd src  || exit -1

test -f ./fail2ban-0.8.4.tar.bz2 || wget http://sourceforge.net/projects/fail2ban/files/fail2ban-stable/fail2ban-0.8.4/fail2ban-0.8.4.tar.bz2/download || exit 0
bunzip2 ./fail2ban-0.8.4.tar.bz2
tar -xvf fail2ban-0.8.4.tar
cd fail2ban-0.8.4
sudo python setup.py install

cat <<'EOT' >/home/br/tmp/jail.conf
# Fail2Ban configuration file
#
# Author: Cyril Jaquier
#
# $Revision: 747 $
#

# The DEFAULT allows a global definition of the options. They can be override
# in each jail afterwards.

[DEFAULT]

# "ignoreip" can be an IP address, a CIDR mask or a DNS host. Fail2ban will not
# ban a host which matches an address in this list. Several addresses can be
# defined using space separator.
ignoreip = 127.0.0.1

# "bantime" is the number of seconds that a host is banned.
bantime  = 600

# A host is banned if it has generated "maxretry" during the last "findtime"
# seconds.
findtime  = 600

# "maxretry" is the number of failures before a host get banned.
maxretry = 5

# "backend" specifies the backend used to get files modification. Available
# options are "gamin", "polling" and "auto". This option can be overridden in
# each jail too (use "gamin" for a jail and "polling" for another).
#
# gamin:   requires Gamin (a file alteration monitor) to be installed. If Gamin
#          is not installed, Fail2ban will use polling.
# polling: uses a polling algorithm which does not require external libraries.
# auto:    will choose Gamin if available and polling otherwise.
backend = auto

[freeswitch-tcp]
enabled  = true
port     = 5060,5061,5080,5081
protocol = tcp
filter   = freeswitch
logpath  = /usr/local/freeswitch/log/freeswitch.log
action   = iptables-allports[name=freeswitch-tcp, protocol=all]
           sendmail-whois[name=FreeSwitch, dest=root, sender=fail2ban@example.org]

[freeswitch-udp]
enabled  = true
port     = 5060,5061,5080,5081
protocol = udp
filter   = freeswitch
logpath  = /usr/local/freeswitch/log/freeswitch.log
action   = iptables-allports[name=freeswitch-udp, protocol=all]
           sendmail-whois[name=FreeSwitch, dest=root, sender=fail2ban@example.org]

[freeswitch-dos]
enabled = true
port = 5060,5061,5080,5081
protocol = udp
filter = freeswitch-dos
logpath = /usr/local/freeswitch/log/freeswitch.log
action = iptables-allports[name=freeswitch-dos, protocol=all]
maxretry = 20
findtime = 10
bantime  = 86400

## JR the rest of the content is commented out, see jail.conf-orig for reference

EOT
sudo cp -a /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf-orig
sudo install -o root -m 644 /home/br/tmp/jail.conf /etc/fail2ban/
rm /home/br/tmp/jail.conf

cat <<'EOT' >/home/br/tmp/fail2ban.conf
# Fail2Ban configuration file
#
# Author: Cyril Jaquier
#
# \$Revision: 629 \$
#

[Definition]

# Option:  loglevel
# Notes.:  Set the log level output.
#          1 = ERROR
#          2 = WARN
#          3 = INFO
#          4 = DEBUG
# Values:  NUM  Default:  3
#
loglevel = 3

# Option:  logtarget
# Notes.:  Set the log target. This could be a file, SYSLOG, STDERR or STDOUT.
#          Only one log target can be specified.
# Values:  STDOUT STDERR SYSLOG file  Default:  /var/log/fail2ban.log
#
#logtarget = /var/log/fail2ban.log -- BR 2/2013
logtarget = /var/log/br/fail2ban.log

# Option: socket
# Notes.: Set the socket file. This is used to communicate with the daemon. Do
#         not remove this file when Fail2ban runs. It will not be possible to
#         communicate with the server afterwards.
# Values: FILE  Default:  /var/run/fail2ban/fail2ban.sock
#
socket = /var/run/fail2ban/fail2ban.sock

EOT
sudo cp -a /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.conf-orig
sudo install -o root -m 644 /home/br/tmp/fail2ban.conf /etc/fail2ban/
rm /home/br/tmp/fail2ban.conf

cat <<'EOT' >/home/br/tmp/freeswitch.conf
# Fail2Ban configuration file
#
# Author: Rupa SChomaker
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>[\w\-.^_]+)
# Values:  TEXT
#
failregex = \[WARNING\] sofia_reg.c:\d+ SIP auth failure \(REGISTER\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>
            \[WARNING\] sofia_reg.c:\d+ SIP auth failure \(INVITE\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =

EOT
sudo install -o root -m 644 /home/br/tmp/freeswitch.conf /etc/fail2ban/filter.d/
rm /home/br/tmp/freeswitch.conf

cat <<'EOT' >/home/br/tmp/freeswitch-dos.conf
# Fail2Ban configuration file
#
# Author: soapee01
#

[Definition]
# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>[\w\-.^_]+)
# Values:  TEXT
#
failregex = \[WARNING\] sofia_reg.c:\d+ SIP auth challenge \(REGISTER\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =

EOT
sudo install -o root -m 644 /home/br/tmp/freeswitch-dos.conf /etc/fail2ban/filter.d/
rm /home/br/tmp/freeswitch-dos.conf

cat <<'EOT' >/home/br/tmp/fail2ban
#!/bin/bash
#
# chkconfig: - 92 08
# description: Fail2ban daemon
#              http://fail2ban.sourceforge.net/wiki/index.php/Main_Page
# process name: fail2ban-server
#
#
# Author: Tyler Owen
#

# Source function library.
. /etc/init.d/functions

# Check that the config file exists
[ -f /etc/fail2ban/fail2ban.conf ] || exit 0

FAIL2BAN="/usr/bin/fail2ban-client"

RETVAL=0

getpid() {
    pid=`ps -eo pid,comm | grep fail2ban- | awk '{ print $1 }'`
}

start() {
    echo -n $"Starting fail2ban: "
    getpid
    if [ -z "$pid" ]; then
        $FAIL2BAN -x start > /dev/null
        RETVAL=$?
    fi
    if [ $RETVAL -eq 0 ]; then
        touch /var/lock/subsys/fail2ban
        echo_success
    else
        echo_failure
    fi
    echo
    return $RETVAL
}

stop() {
    echo -n $"Stopping fail2ban: "
    getpid
    RETVAL=$?
    if [ -n "$pid" ]; then
        $FAIL2BAN stop > /dev/null
    sleep 1
    getpid
    if [ -z "$pid" ]; then
        rm -f /var/lock/subsys/fail2ban
        echo_success
    else
        echo_failure
    fi
    else
        echo_failure
    fi
    echo
    return $RETVAL
}

# See how we were called.
case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        getpid
        if [ -n "$pid" ]; then
                echo "Fail2ban (pid $pid) is running..."
                $FAIL2BAN status
        else
                RETVAL=1
                echo "Fail2ban is stopped"
        fi
        ;;
  restart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac

exit $RETVAL
EOT
sudo install -o root -m 755 /home/br/tmp/fail2ban /etc/init.d/
rm /home/br/tmp/fail2ban

exit 0

