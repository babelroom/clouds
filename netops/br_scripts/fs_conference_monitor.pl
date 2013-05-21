#!/usr/bin/perl

# ---
#BR_description: Detect and relay FreeSwitch conference status, primarily conference starting and terminating
#BR_startup: foreach_freeswitch=always
#BR__END: 
# ---

# ---
$|++;
use BRDB;
use BRJobs;
use EStream;
use URI::Escape;
use REST::Client;

# ---
$dbh = undef;
$last_db_action_time = undef;

# ---
sub maybe_db_reopen
{
    $now = time();
    if ((!defined($dbh)) or (!defined($last_db_action_time)) or (($now-$last_db_action_time)>=300)) {
        print STDERR "No DB connection or too long since last DB activity, reopening connection()\n";
        db_disconnect($dbh) if defined $dbh;
        $dbh = undef;
        $dbh = db_quick_connect() or die;
        }
    $last_db_action_time = $now if defined($dbh);
}

# ---
$hostname=$ipv4=$system_id=undef;
$es_port=80;    # default
foreach(split ',', $ENV{BR_PARAMETERS}){
    next if not /^(.*)=(.*)$/;
    $hostname = $2 if $1 eq 'hostname';
    $ipv4 = $2 if $1 eq 'ipv4';
    $es_port = $2 if $1 eq 'es_port';
    $system = $2 if $1 eq 'system_id';
}

# ---
sub conference_action
{
    my $timestamp = shift;
    my $cid = shift;
    my $field = shift;
    my $timestamp = shift;
    maybe_db_reopen();
    $timestamp = $dbh->quote($timestamp);
    my $state = '';
    if ($field eq 'actual_start') {
        $state = 'started';
        db_exec($dbh,"UPDATE conferences SET $field=$timestamp, state='$state', updated_at=NOW() WHERE id='$cid' AND state='deployed'",'_updated') or die;
        return $_updated;
        }
    elsif ($field eq 'actual_end') {
        $state = 'ended';
        # for rooms --- conferences don't die
        #db_exec($dbh,"UPDATE conferences SET $field=$timestamp, state='$state', updated_at=NOW() WHERE id='$cid' AND state='live'",'_updated') or die;
        db_exec($dbh,"UPDATE conferences SET $field=$timestamp, updated_at=NOW() WHERE id='$cid' AND state='live'",'_updated') or die;
        return $_updated;
        }
    else {
        die "[$timestamp] unknown conference action [$field] ($timestamp) for cid=$cid\n";
        }
    return 0;
}

# ---
sub recording_action
{
    my $timestamp = shift;
    my $cid = shift;
    my $path = shift;
    my $timestamp = shift;

    my $client = REST::Client->new();
    return 0 if not defined $client;
    $client->setHost("http://$ipv4:$es_port");
    $fullpath = uri_unescape($path);
    print "checking for recording ... HEAD [$fullpath]\n";
    $client->HEAD($fullpath);
    my $rc = $client->responseCode();
    $client = undef;
    if ($rc !~ /^2.*/) {
        print "[$timestamp] recording not found [$fullpath]\n";
        return 0;
        }
    maybe_db_reopen();
    print "[$timestamp] queuing job for [$fullpath]\n";
    my $name = 'save_recording.pl-$cid-$ts-$path';
    return job_launch($dbh,$n,'save_recording.pl',"rhost=$ipv4:$es_port,cid=$cid,ts=$timestamp,path=$path");
}

# ---
sub channel_action
{
    my $timestamp = shift;
    my $uuid = shift;
    my $kvs = shift;
    maybe_db_reopen();
    $uuid = $dbh->quote($uuid);
    my %vars = ();
    foreach my $kv (split /,/, $kvs) {
        $vars{$1} = uri_unescape($2) if $kv=~/^([^=]*)=(.*)$/ or $kv=~/^(.+)()$/;
        }
    my $affected;
    if (defined $vars{started}) {
        if (length($vars{'cid'}) and length($vars{'pid'})) {
            my $data;
            BRDB::db_select2("SELECT id FROM calls WHERE uuid=$uuid", \$data, $dbh) or die;
            if ($#{$data}) {
                BRDB::db_exec2($dbh,"INSERT INTO calls (uuid,created_at,updated_at,started,meta_data,conference_id,person_id) VALUES ($uuid,NOW(),NOW()"
                    . "," . $dbh->quote($vars{started})
                    . "," . $dbh->quote($kvs)
                    . "," . $vars{'cid'}
                    . "," . $vars{'pid'}
                    . ")",\$affected) or die;
                }
            else {
                #print STDERR "WOULD BE: duplicate uuid on insert [$uuid]\n"; -- silently ignore ...
                }
            }
        else {
            print STDERR "[$timestamp] missing cid or pid on record: $kvs\n";
            }
        }
    else {
        my $ended = $dbh->quote($vars{ended});
        my $md = $dbh->quote($kvs);
        BRDB::db_exec2($dbh,"UPDATE calls SET ended=$ended, meta_data=CONCAT(meta_data,$md), updated_at=NOW() WHERE uuid=$uuid AND ended IS NULL",\$affected) or die;
        return $affected;
        }
    return 0;
}

# ---
sub msg
{
    my $length = shift;
    my $data = shift;
    my $timestamp = shift;
#    foreach my $kv(split(/\r\n/, $data)) {
# TODO fix indenting
    my $kv = $data;
        if ($kv =~ /^Conference-([^-]*)-([^:]+):[\s*](.*)$/) {
            conference_action($timestamp, $1,$2,$3);
            }
        elsif ($kv =~ /^Recording-([^-]*)-([^:]+):[\s*](.*)$/) {
            recording_action($timestamp, $1,$2,$3);
            }
        elsif ($kv =~ /^Channel-([^_]*):[\s*](.*)$/) {
            channel_action($timestamp, $1,$2);
            }
        else {
            print STDERR "[$timestamp] Unknown conference status data[$kv]\n";
            }
#        }
}

# ---
$esh = estream_open("http://$ipv4:$es_port/conference/_status") or die;

# ---
maybe_db_reopen();
my $data;
my $len;
my $timestamp=undef;  # returns deciseconds :-)
while(($len=estream_read_with_timestamp($esh,\$data,\$timestamp))) {
    msg($len, $data, $timestamp);
}

# ---
#close(F);
estream_close($esh) if $esh;
db_disconnect($dbh) if defined $dbh;

# ---
exit 0;

