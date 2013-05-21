#!/usr/bin/perl

# ---
# test
# test a DB query
# ---

# ---
$|++;
use BRDB;
use Data::Dumper;

# ---
$rdsn = 'dbi:mysql:go3_development:127.0.0.1:3306';
$dbruser = 'root';
$dbrpass = 'jjj';
sub db_remote_connect { $dbrh = db_connect($rdsn, $dbruser, $dbrpass,'REMOT'); }

# ---
db_remote_connect() or die;

# ---
my $rows;
$sql = "
SELECT id, conference_id FROM invitations 
WHERE
    user_id 
IN
( SELECT id FROM users
WHERE
    crypted_password IS NULL AND email_address = '' AND last_name = '')
AND
    updated_at < (NOW() - INTERVAL 48 HOUR)
";
BRDB::db_select2($sql,\$rows,$dbrh) or die;

print Dumper($rows);

# ---
db_disconnect($dbrh);

# ---
exit 0;

