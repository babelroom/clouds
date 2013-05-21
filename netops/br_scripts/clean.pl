#!/usr/bin/perl

# ---
#BR_description: Clean
#BR_startup: foreach_provisioning=22 23 * * *
#BR__END: 
# ---

# ---
$|++;
use BRDB;

# ---
$rdsn=$dbruser=$dbrpass=$system_id=undef;
foreach(split ',', $ENV{BR_PARAMETERS}){
    next if not /^(.*)=(.*)$/;
    $rdsn = $2 if $1 eq 'dsn';
    $dbruser = $2 if $1 eq 'dbuser';
    $dbrpass = $2 if $1 eq 'dbpass';
    $system_id = $2 if $1 eq 'system_id';
    $url_for_email = $2 if $1 eq 'url_for_email';
}

# ---
$dsn = $ENV{BR_DSN};
$dbuser = $ENV{BR_DBUSER};
$dbpass = $ENV{BR_DBPASS};

# ---
sub db_local_connect { $dbh = db_connect($dsn, $dbuser, $dbpass,'LOCAL'); }
sub db_remote_connect { $dbrh = db_connect($rdsn, $dbruser, $dbrpass,'REMOT'); }

# ---
db_remote_connect() or die;
db_local_connect() or die;

# ---
BRDB::db_exec2($dbh,"DELETE FROM logs WHERE updated_at<SUBDATE(NOW(),INTERVAL 1 MONTH)",\$rows) or die;
BRDB::db_exec2($dbh,"DELETE FROM jobs WHERE ended IS NOT NULL AND updated_at<SUBDATE(NOW(),INTERVAL 1 WEEK)",\$rows) or die;
BRDB::db_exec2($dbrh,"DELETE FROM callees WHERE ended IS NOT NULL AND ended<SUBDATE(NOW(),INTERVAL 90 DAY)",\$rows) or die;

# --- purge inactive users that were created dynamically to server "self register"
# still smart? TMP TODO
BRDB::db_exec2($dbrh,"DELETE FROM invitations WHERE user_id IN (SELECT id FROM users WHERE crypted_password IS NULL AND email_address = '' AND last_name = '') AND updated_at < (NOW() - INTERVAL 48 HOUR)",\$rows) or die;

# ---
db_disconnect($dbh);
db_disconnect($dbrh);

# ---
exit 0;
