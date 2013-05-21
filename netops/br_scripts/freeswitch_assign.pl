#!/usr/bin/perl

# ---
#BR_description: Assign pending conferences to active freeswitch conference instances
#BR_startup: running=always
#BR__END: 
# ---

# ---
$|++;
use BRDB;

# ---
sub get_pending_conferences
{
    $conferences = [];
    db_select("SELECT id,updated_at FROM conferences WHERE is_deleted IS NULL AND (start IS NULL OR start>=SUBTIME(NOW(),'00:15:00.0')) AND state = 'undeployed'",'conferences',$dbh) or return 0;
    return $#{$conferences}+1;
}

# ---
sub get_freeswitch_servers
{
    $servers = [];
    db_select('SELECT id,name,access FROM systems WHERE access LIKE \'%ipv4=%\' AND system_type LIKE \'%freeswitch%\'','servers',$dbh) or return 0;
    return $#{$servers}+1
}

# ---
sub assign_conferences_to_servers
{
    # just assign them all to the first FS server - TODO (obviously)
    my $fs = ${$servers}[0];
    foreach my $c(@{$conferences}) {
        my $config = $dbh->quote("$fs->{access}");
# this will only work for people added before the conference was touched -- now with invitations the conference doesn't get touched ...
#        db_exec($dbh,"UPDATE people SET updated_at=NOW(), fs_server=$config WHERE conference_id=$c->{id} AND is_deleted IS NULL",'_rows') or die;
        db_exec($dbh,"UPDATE conferences SET fs_server=$config,state='assigned',updated_at=NOW() WHERE id=$c->{id} AND updated_at='$c->{updated_at}'","_rows") or die;
        }
    return 1;
}

# ---
sub assign_people_to_servers
{
    # again first server only (TODO)
    my $fs = ${$servers}[0];
    my $config = $dbh->quote("$fs->{access}");
    my $rows = undef;
    BRDB::db_exec2($dbh, "UPDATE people SET updated_at=NOW(), fs_server=$config WHERE conference_id IS NOT NULL AND pin IS NOT NULL AND fs_server IS NULL", \$rows) or die;
    return $rows>0 ? 1 : 0;
}

# ---
$dbh = db_quick_connect();

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
{
    my $did_something = 0;

    # ---
    if (get_freeswitch_servers()) {
        # ---
        if (get_pending_conferences()) {
            if (assign_conferences_to_servers()) {
                $did_something = 1;
                }
            }
        # ---
        $did_something = 1 if assign_people_to_servers();
        }

    # ---
    sleep $ENV{BR_SLEEP_SHORT} if not $did_something;
}

# ---
db_disconnect($dbh);

exit 0;

