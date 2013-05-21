#!/usr/bin/perl

# ---
#BR_description: Synchronize conference data between netops and provisioning using DB
#BR_startup: foreach_provisioning=always
#BR__END: 
# ---

# ---
$|++;
use BRDB;
use String::Random;

# ---
$rdsn=$dbruser=$dbrpass=$system_id=undef;
foreach(split ',', $ENV{BR_PARAMETERS}){
    next if not /^(.*)=(.*)$/;
    $rdsn = $2 if $1 eq 'dsn';
    $dbruser = $2 if $1 eq 'dbuser';
    $dbrpass = $2 if $1 eq 'dbpass';
    $system_id = $2 if $1 eq 'system_id';
}
$dsn = $ENV{BR_DSN};
$dbuser = $ENV{BR_DBUSER};
$dbpass = $ENV{BR_DBPASS};
$pat = new String::Random or die;

# ---
sub db_local_connect { $dbh = db_connect($dsn, $dbuser, $dbpass,'LOCAL'); }
sub db_remote_connect { $dbrh = db_connect($rdsn, $dbruser, $dbrpass,'REMOT'); }

# ---
$global_dialin = undef;
sub get_dialin
{
    return $global_dialin if defined $global_dialin;
    db_select("SELECT name,config FROM interconnects",'_numbers',$dbh) or die;
    foreach my $n (@{$_numbers}) {
        my %vars = ();
        foreach(split ',', $n->{config}){
            $vars{$1} = '' if /^([^=]*)$/;
            $vars{$1} = $2 if /^([^=]*)=(.*)$/;
            }
        next if defined $vars{disabled};
        $global_dialin .= "$n->{name}\n";
        }

    return $global_dialin;
}

# ---
sub get_new_or_modified_provisioning_conferences
{
    # one record at a time means less chance for changes to the record between when we read & when we save
    my $sql = "SELECT * FROM conferences WHERE (schedule IS NOT NULL) AND ((deployed_at IS NULL) OR (updated_at>=deployed_at)) ORDER BY updated_at LIMIT 1";
    $provisioning_conferences = [];
    db_select($sql,'provisioning_conferences',$dbrh) or die;
    return 1;
}

# ---
sub update_conference_close_out
{
    my $l = shift;
    my $next_state = shift;
    my $sql = shift;

    # --- update remote (provisioning) system
    if (defined $sql) {
        db_exec($dbrh, $sql, '_updated');
        }
    else {
        $_updated = 1;
        }
    if ($_updated) {
        $next_state = $dbh->quote($next_state);
        $sql = "UPDATE conferences SET state=$next_state,updated_at=NOW() WHERE id=$l->{id}";
        db_exec($dbh, $sql,'_updated') or die;
        if ($_updated) {
            return 1;
            }
        print STDERR "SQL updated failed unexpectedly: [$sql]\n" if not $_updated;
        }
    else {
        print STDERR "failed to update provisioning conference [$l->{origin_id}] in system [$system_id] from local [$l->{id}]. next_state=$next_state\n";
        }
    return 0;
}

# ---
sub update_conference_ended_out
{
    my $l = shift;

    # --- pull the provisioning conference record
    # --- TODO tmp. just added is_deleted condition to next query ... not sure its 100% correct
    db_select("SELECT id,start,schedule,actual_end,updated_at FROM conferences WHERE id=$l->{origin_id} AND is_deleted IS NULL", '_data', $dbrh) or die;
    return update_conference_close_out($l,'delete',undef) if $#{$_data}<0;   # conference deleted on provisioning system?
    die if $#{$_data};  # i.e. record count > 1
    my $r = ${$_data}[0];
    #die "conference already closed on provisioning system? $l->{id}/$l->{origin_id}\n" if defined $r->{actual_end}; 
    if (defined $r->{actual_end}) {
        print STDERR "conference already closed on provisioning system? (local id/origin id) $l->{id}/$l->{origin_id}\n";
        return 0;
        }

    # --- once off?
    if ($r->{schedule} eq 'o') {
        my $ae = $dbrh->quote($l->{actual_end});
        my $ua = $dbrh->quote($r->{updated_at});
        # --- copy/setup whatever media files are needed
        return update_conference_close_out($l, 'media_ready', "UPDATE conferences SET actual_end=$ae WHERE id=$r->{id}");
        }

    # --- it's recurring, clone the row in the provisioning system
    # !!!! The new remote clone will become the completed conference, associated with recordings etc. !!!!
    # !!!! The current remote conference will be reset to not-yet-started ready to be used again !!!!
    # ----
    db_exec($dbrh, "CREATE TEMPORARY TABLE conferences_tmp SELECT * FROM conferences WHERE id=$r->{id}", '_updated') or die;
    db_exec($dbrh, "UPDATE conferences_tmp SET id=NULL, schedule = 'o', uri=NULL", '_updated') or die;
    db_exec($dbrh, "INSERT INTO conferences SELECT * FROM conferences_tmp", '_updated') or die;
    db_select("SELECT LAST_INSERT_ID() AS id", '_data',$dbrh) or die;
    my $new_origin_id = ${$_data}[0]->{id};
    die if not $new_origin_id+0;
    db_exec($dbrh, "DROP TABLE conferences_tmp", '_updated') or die;
# --- THIS IS NEW and NOT FULLY TESTED
    db_exec($dbrh, "CREATE TEMPORARY TABLE invitations_tmp SELECT * FROM invitations WHERE conference_id=$r->{id}", '_updated') or die;
    db_exec($dbrh, "UPDATE invitations_tmp SET id=NULL,conference_id=$new_origin_id,updated_at=NOW()", '_updated') or die;
    db_exec($dbrh, "INSERT INTO invitations SELECT * FROM invitations_tmp", '_updated') or die;
    db_exec($dbrh, "DROP TABLE invitations_tmp", '_updated') or die;
# --- (end) THIS IS NEW and NOT FULLY TESTED

    # --- it's recurring, clone row locally 
    # !!!! The new local clone will become the new as yet undeployed conference !!!!
    # !!!! The current local copy will continue it's lifecycle thru closed then deleted !!!!
    # ---
    db_exec($dbh, "CREATE TEMPORARY TABLE conferences_tmp SELECT * FROM conferences WHERE id=$l->{id}", '_updated') or die;
    # -- don't set state yet, wait for people to be reassigned first to avoid race condition with assign and deploy scripts
    db_exec($dbh, "UPDATE conferences_tmp SET id=NULL, fs_server=NULL, actual_start=NULL, actual_end=NULL, updated_at=NOW()", '_updated') or die;
    db_exec($dbh, "INSERT INTO conferences SELECT * FROM conferences_tmp", '_updated') or die;
    db_select("SELECT LAST_INSERT_ID() AS id", '_data',$dbh) or die;
    my $new_local_id = ${$_data}[0]->{id};
    die if not $new_local_id+0;
    db_exec($dbh, "DROP TABLE conferences_tmp", '_updated') or die;

    #  ---
    my $start_interval_update = '';
    if ($r->{schedule} ne 's') {
        die if not defined $r->{start};
        # add an interval to the start time
        my %time_interval_hash = (
            undef => '0 DAY',
            '' => '0 DAY',
            'e' => '1 DAY',
#            'd' => weekday, -- how to do this?
            'w' => '1 WEEK',
            'b' => '2 WEEK',
            'm' => '1 MONTH',
            'q' => '1 QUARTER',
            );
        $start_interval_update = ", start=DATE_ADD(start,INTERVAL $time_interval_hash{$r->{schedule}})";
        }
    db_exec($dbrh, "UPDATE conferences SET actual_start=NULL$start_interval_update WHERE id = $r->{id}", '_updated') or die;
    db_exec($dbh, "UPDATE conferences SET origin_id=$new_origin_id, updated_at=NOW() WHERE id = $l->{id}", '_updated') or die;
    # --- this is starting to get pretty messy
    db_exec($dbrh, "UPDATE callees SET conference_id=$new_origin_id WHERE conference_id=$r->{id}", '_updated') or die;
    db_exec($dbh, "UPDATE people SET fs_server=NULL, deployed_at=NULL, updated_at=NOW(), conference_id=$new_local_id WHERE conference_id=$l->{id}", '_updated') or die;
    db_exec($dbh, "UPDATE conferences SET state='undeployed', updated_at=NOW() WHERE id = $new_local_id", '_updated') or die;
    return 1;   # return 1, to mark work done, so we iterate immediately, complete the process on the next iteration
}

# ---
sub conferences_status_updated_out
{
    $_data=[];
    my $did_something = 0;
    # -- why the deployed_at>updated_at here?? (reviewed once)
    db_select("SELECT id,state,fs_server,actual_start,actual_end,updated_at,origin_id FROM conferences WHERE (state='ended' OR state='started') AND system_id=$system_id AND is_deleted IS NULL ORDER BY updated_at", '_data',$dbh) or die;
    foreach my $l(@{$_data}) {
        print "conference started/ended id=[$l->{id}]\tstate=[$r->{state}]\tactual_start=[$r->{actual_start}]\tactual_end=[$r->{actual_end}]\n";
        if ($l->{state} eq 'ended') {
            $did_something = 1 if update_conference_ended_out($l);
            next;
            }
        my $as = $dbrh->quote($l->{actual_start});
        my $ipv4 = $1 if $l->{fs_server} =~ /ipv4=([^,]*)/;
        my $es_port = $1 if $l->{fs_server} =~ /es_port=([^,]*)/;
        my $fs = $dbrh->quote("id=$l->{id},fs_server=$ipv4:$es_port");
        $did_something = 1 if update_conference_close_out($l, 'live', "UPDATE conferences SET actual_start=$as, config=$fs, deployed_at=NOW() WHERE id=$l->{origin_id}");
        }
    return $did_something;
}

# ---
sub conferences_queue_created
{
    $_data=[];
    my $did_something = 0;
    # -- why the deployed_at>updated_at here?? (reviewed once)
    db_select("SELECT id,state,fs_server,updated_at,origin_id FROM conferences WHERE (state='queue_created') AND system_id=$system_id ORDER BY updated_at", '_data',$dbh) or die;
    foreach my $l(@{$_data}) {
        print "conference queue created id=[$l->{id}]\tstate=[$r->{state}]\tupdated_at=[$r->{updated_at}]\n";
        my $ipv4 = $1 if $l->{fs_server} =~ /ipv4=([^,]*)/;
        my $es_port = $1 if $l->{fs_server} =~ /es_port=([^,]*)/;
        my $fs = $dbrh->quote("id=$l->{id},fs_server=$ipv4:$es_port");
        $did_something = 1 if update_conference_close_out($l, 'ready_to_deploy', "UPDATE conferences SET config=$fs, deployed_at=NOW() WHERE id=$l->{origin_id}");
        }
    return $did_something;
}

# ---
sub get_local_conferences
{
    my $ids = '0';
    for my $r(@{$provisioning_conferences}) {
#        if (defined $r->{actual_end}) {
#            print STDERR "closed provisioning conference modified! system=$system_id, id=$r->{id}\n";
#            }
        print "id=[$r->{id}]\tname=[$r->{name}]\tschedule=[$r->{schedule}]\tstart=[$r->{start}]\n";
        $ids.=qq!,$r->{id}!;
        }
    $local_conferences = [];
    db_select("SELECT * FROM conferences WHERE system_id = '$system_id' AND origin_id IN ($ids)",'local_conferences',$dbh) or die;
    return 1;
}

# ---
sub create_provisioning_to_local_map
{
    %provisioning_to_local_map = ();
    for my $r(@{$local_conferences}) {
        die if $r->{system_id} ne $system_id;
        next if not defined $r->{origin_id};
        $provisioning_to_local_map{$r->{origin_id}}=$r;
        }
}

# ---
sub DEPRECIATED_new_user
{
    my $cid = shift;
    my $e = shift;
    my $name = shift;
    my $last_name = shift;
    my $phone = shift;
    my $configuration = shift;
    my $token = shift;

    # no email or token, shouldn't happen, but drop on the floor if it does...
    #return 0 if not length($e) and not length($token);
    die if not length($e) and not length($token);

    # here is how we'll deal with this in the short-term
    # take a pin with NULL use fields (email,person_id etc.)
    # assign it and record use meta-data, also make sure we set the updated_at field
    # later we can recover/re-use based on meta-data and staleness from updated_at field
    # take a pin with a NULL use field. Update the pin record with updated_at and use==conference_id 
    # at a later point we can deal with recovering old pins based on (1) updated_at field and (2) conference_id
    $_pins=undef;
    db_select("SELECT id,pin,updated_at FROM pins WHERE person_id IS NULL LIMIT 1",'_pins',$dbh) or die;
    if ($#{$_pins}<0) {
        die "Out of PINs!";
        }
    my $p = ${$_pins}[0];
    $e = $dbh->quote($e);
    $name = $dbh->quote($name);
    $last_name = $dbh->quote($last_name);
    $phone = $dbh->quote($phone);
    $configuration = $dbh->quote($configuration);
    $token = $dbh->quote($token);
    $dialin = $dbh->quote(get_dialin());
    db_exec($dbh,"INSERT INTO people (name,last_name,dialout,dialin,email,configuration,conference_id,created_at,updated_at,system_id,pin,token) VALUES ($name,$last_name,$phone,$dialin,$e,$configuration,$cid,NOW(),NOW(),$system_id,'$p->{pin}',$token)") or die;
    $_rows=undef;
    # token or e may be NULL so the WHERE claus here may not operate as expected ... therefore the person_id field 
    # in the pins table may not be correct ...............
    db_exec($dbh,"UPDATE pins SET updated_at=NOW(),email=$e,person_id=(SELECT id FROM people WHERE email=$e AND conference_id=$cid AND system_id=$system_id AND pin='$p->{pin}' AND token=$token),conference_id=$cid,system_id=$system_id WHERE id=$p->{id} AND updated_at='$p->{updated_at}'",'_rows') or die;
    if ($_rows<1) {
        die "failed to mark PIN record as used!";
        return 0;
        }
    return 1;
}

# ---
sub DEPRECIATED_delete_user
{
    my $cid = shift;
    my $e = shift;
# --- TODO NEED TO DELETE the INVITATION !!!!
    db_exec($dbh,"UPDATE people SET is_deleted=1,updated_at=NOW() WHERE conference_id='$cid' AND id='$e' AND is_deleted IS NULL") or die;
    return 1;
}

# ---
sub DEPRECIATED_update_people
{
    print "updating people (invitations) for conference [$l->{id}]:\n";
    my $cid = shift;
    my @ukeys = ();
    my %emails = ();
    my %tokens = ();
    my %names = ();
    my %last_names = ();
    my %phones = ();
    my %configurations = ();
    my $i = 0;
    foreach my $line(split /\r\n/, shift) {
#        next if not /^([^:]):([^:]):([^:]):([^:]):([^:]):$/;
#        my ($role,$name,$last_name,$email,$phone) = ($1,$2,$3,$4,$5,$6);
        my ($role,$name,$last_name,$email,$phone,$token) = split(/:/,$line);
#print STDERR "[$line] => role=$role, name=$name, last_name=$last_name, email=$email, phone=$phone, token=$token\n";
        my $ukey = "$email-$token";
        $names{$ukey} = "$name";
        $emails{$ukey} = "$email";
        $last_names{$ukey} = "$last_name";
        $phones{$ukey} = "$phone";
        $configurations{$ukey} = "$role";
        $tokens{$ukey} = "$token";
        push @ukeys, $ukey;
        print "\t$i .. [$ukey] $role $name $last_name $email $phone $token\n";
        $i++;
        }
#    my @emails = split /\r\n/, shift;
    $people = [];
    db_select("SELECT id,email,pin,system_id,token FROM people WHERE conference_id=$cid AND is_deleted IS NULL",'people',$dbh) or die;
    my %people_map = ();
    for my $p(@{$people}) {
        die if $p->{system_id} ne $system_id;
        my $ukey = "$p->{email}-$p->{token}";
        $people_map{$ukey}=$p->{id};
# TODO: XXXXX update_user????
        print "\tupdate_user (NOT YET IMPLEMENTED) id/ukey = [$p->{id}/$ukey]\n";
        }
    foreach my $u (@ukeys) {
        next if $u eq '';
        if (not defined $people_map{$u}) {
            print "\tnew_user $cid $u\n";
            new_user($cid,$emails{$u},$names{$u},$last_names{$u},$phones{$u},$configurations{$u},$tokens{$u}) or return 0 if not defined $people_map{$u};
            }
        $people_map{$u} = undef;
        }
    foreach my $u (keys %people_map) {
        print "\tdelete_user $cid $people_map{$u}\n";
        delete_user($cid,$people_map{$u}) or return 0 if defined $people_map{$u};
        }
    return 1;
}

# ---
sub update_conference_in
{
    my $l = shift;
    my $r = shift;
# TODO, in the rooms scenario this makes no difference
#    if (defined $l->{actual_end}) {
#        print "not updating people (invitations) for conference [$l->{id}] marked ended.\n";
#        }
#    else {
        # do not update people (invitations) for conferences which have ended
#        update_people($l->{id},$r->{participant_emails}) or return 0; -- now depreciated as we no longer update based on participant emails
#        }
    my $name = $dbh->quote($r->{name});

# TODO: ok to go ahead and deploy changes to conference schedule (mark undeployed to make sure they get deployed)
#    print STDERR "ignoring any schedule change in update from (schedule/start) [$r->{schedule}/$r->{start}] to [$l->{schedule}/$l->{start}] on conference local=$l->{id}, remote/system=$r->{id}/$system_id\n";
# 
    my $start = ($r->{start} eq 's') ? 'NULL' : $dbh->quote($r->{start});
    my $schedule = ($r->{schedule} eq 's') ? 'NULL' : $dbh->quote($r->{schedule});
    # state -> undeployed as we've updated people (avoid race condition with assign and deployment scripts)
    db_exec($dbh,"UPDATE conferences SET name=$name,start=$start,schedule=$schedule,state='undeployed',updated_at=NOW() WHERE id='$l->{id}' AND is_deleted IS NULL") or return 0;
    db_exec($dbrh,"UPDATE conferences SET deployed_at=NOW() WHERE id='$r->{id}' AND is_deleted IS NULL AND updated_at = '$r->{updated_at}'") or return 0;
    return 1;
}

# ---
sub delete_conference
{
    my $l = shift;
    my $r = shift;
    die if $l->{origin_id} ne $r->{id};
    db_exec($dbh,"UPDATE people SET is_deleted=1,updated_at=NOW() WHERE conference_id=$l->{id}") or return 0;
    db_exec($dbh,"UPDATE conferences SET is_deleted=1,updated_at=NOW() WHERE id=$l->{id}") or return 0;
    db_exec($dbrh,"DELETE FROM conferences WHERE id=$r->{id}") or return 0;
    return 1;
}

# ---
sub cross_reference_remote_and_local_conferences
{
    my $did_something = 0;

    # --- new
    for my $r(@{$provisioning_conferences}) {
        my $l;
        if (defined ($l=$provisioning_to_local_map{$r->{id}})) {
            if ($r->{is_deleted}) {
                print "remote conference [$r->{id}] deleted. local [$l->{id}]\n";
                delete_conference($l,$r);
                }
            else {
                print "remote conference [$r->{id}] updated. local [$l->{id}]\n";
                update_conference_in($l,$r);
                }
            }
        else {
            # new conference in provisioning
            my $name = $dbh->quote($r->{name});
            my $schedule = $dbh->quote($r->{schedule});
            my $start = $dbh->quote($r->{start});
            my $origin_id = $dbh->quote($r->{id});
            my $key = $dbrh->quote($pat->randregex("[a-zA-Z0-9]{16}"));
            if (!db_exec($dbh,"INSERT INTO conferences (name,created_at,updated_at,state,system_id,schedule,start,origin_id,conference_key) VALUES ($name,NOW(),NOW(),'undeployed',$system_id,$schedule,$start,$origin_id,$key)")) {
                print "inserted new local conference from remote id=[$r->{id}] (next iteration will continue the replication)\n";
                # take, no further action, if successfully inserted, the next iteration will pick this up as an edit and continue the replication
                }
            }
#        print " #$r->{id} [$r->{name}]\n";
        $did_something = 1;
        }

    for my $r(@{$provisioning_conferences}) {
#        if (defined $r->{actual_end}) {
#            print STDERR "closed provisioning conference modified! system=$system_id, id=$r->{id}\n";
#            }
        print "id=[$r->{id}]\tname=[$r->{name}]\tschedule=[$r->{schedule}]\tstart=[$r->{start}]\n";
        $ids.=qq!,$r->{id}!;
        }
    return $did_something;
}

# ---
db_remote_connect() or die;
db_local_connect() or die;

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
{
    print "--------------------------------------------------------------------------------\n";
    print "New or modified conferences on provisioning system $system_id\n";
    print "--------------------------------------------------------------------------------\n";
    my $did_something = 0;

    $global_dialin = undef;

    get_new_or_modified_provisioning_conferences();

    get_local_conferences();

    create_provisioning_to_local_map();

    $did_something = 1 if cross_reference_remote_and_local_conferences();

    $did_someting = 1 if conferences_queue_created();

    $did_something = 1 if conferences_status_updated_out();

    sleep $ENV{BR_SLEEP_SHORT} if not $did_something;
    print "--------------------------------------------------------------------------------\n";
}

# ---
db_disconnect($dbh);
db_disconnect($dbrh);

exit 0;
