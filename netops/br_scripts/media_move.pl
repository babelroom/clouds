#!/usr/bin/perl

# ---
#BR_description: Program to migrate media from a FS server once conference has completed
#BR_startup: running=always
#BR__END: 
# ---


#
# NB NB NB NB
# this is now actually quite depreciated.
# 1. standing conferences don't end
# 2. the naming scheme is different
# 3. save_recording.pl is used to save files whenever they end
# 4. so this always hits a 404 and then progresses the conference ...
#

# ---
# detect conferences in 'media_ready' state and move them to 'media_done' state
# ---


# ---
$|++;
use BRDB;
use REST::Client;

# ---
my $RECPATH = "/br_media/conf_recordings";  # physical and virtual are the same right now

# ---
sub dbrh_open
{
    my $access = shift;
    my ($rdsn,$dbruser,$dbrpass);
    foreach(split ',', $access){
        next if not /^(.*)=(.*)$/;
        $rdsn = $2 if $1 eq 'dsn';
        $dbruser = $2 if $1 eq 'dbuser';
        $dbrpass = $2 if $1 eq 'dbpass';
#        $system_id = $2 if $1 eq 'system_id';
#        $url_for_email = $2 if $1 eq 'url_for_email';
        }
    return db_connect($rdsn, $dbruser, $dbrpass,'REMOT');
}

# ---
sub conference_path { my $c = shift; return sprintf("%s-%012d-000.wav", $c->{conference_key}, $c->{id}); }
sub client_down     { $client = undef; $client_rhost = undef; }
sub client_up
{
    my $rhost = shift;
    die if not defined $rhost;
    client_down() unless $rhost eq $client_rhost;
    return 1 if defined $client;
    $client = REST::Client->new();
    return 0 if not defined $client;
    $client_rhost = $rhost;
    $client->setHost("http://$client_rhost");
    return 1;
}

# ---
sub s3_down         { %s3_vars = (); }
sub s3_up
{
    return 1 if defined $s3_vars{_};
    my $data;
    BRDB::db_select2("SELECT access FROM systems WHERE system_type LIKE '%s3%'",\$data,$dbh) or die;
    foreach $r(@{$data}) {
        %vars = ();
        foreach $kv (split /,/, $r->{access}) {
            $vars{$1} = $2 if $kv=~/^([^=]*)=(.*)$/ or $kv=~/^(.*)()$/;
            }
        next if defined $vars{disabled};
        %s3_vars = %vars;
        $s3_vars{_} = '';
        return 1;
        }
    print STDERR "no s3 storage configuration found\n";
    return 0;
}

# ---
sub start_move
{
    my $c = shift;
    my $rhost = shift;
    my $conffile = conference_path($c);
    my $fullpath = "$RECPATH/$conffile";
    die if not client_up($rhost);
    print "HEAD [$fullpath]\n";
    $client->HEAD($fullpath);
    my $rc = $client->responseCode();
    if ($rc eq '404') {
        # media file does not exist, progress
        print "no media for conference [$c->{id}]\n";
        return 'media_done';
        }
    elsif ($rc eq '200') {
        return undef if not s3_up();
        my $data =<<__EOT__
AWSAccessKeyId: $s3_vars{AWSAccessKeyId}
AWSSecretAccessKey: $s3_vars{AWSSecretAccessKey}
Bucket: $s3_vars{Bucket}
URLPrefix: $s3_vars{URLPrefix}
Key: $conffile
Path: $RECPATH
File: $conffile
Content-Type: audio/x-wav

__EOT__
;
        $client->POST("$fullpath.xfer",$data);
        $rc = $client->responseContent();
        if ($rc eq '200') {
            print STDERR "failed to POST xfer data for conference [$c->{id}]\n";
            return undef;
            }
        return 'media_sync';
        }
    else {
        print STDERR $rhost . "->HEAD returned HTTP status $rc\n";
        return undef;
        }
}

# ---
sub delete_or_stderr
{
    my $p=shift;
    $client->DELETE($p);
    print STDERR "client->DELETE($p) failed: $rc\n" if (($rc=$client->responseCode()) ne '200');
}

# ---
sub delete_files
{
    my $rhost = shift;
    my $mediapath = shift;
    die if not client_up($rhost);
    # errors are non-fatal, log them only
    delete_or_stderr("$mediapath.xfer.progress");
    delete_or_stderr("$mediapath.xfer");
    delete_or_stderr("$mediapath");
    return 'media_done';
#    return 'media_ready';
}

# ---
sub create_media_record
{
    my $c = shift;
    my $mediapath = shift;
    my $vars_ref = shift;
    my $dbrh = dbrh_open($c->{access});
    return 0 unless $dbrh;
    my %vars = %$vars_ref;
    my ($n,$ct) = ($dbrh->quote($vars{Key}),$dbrh->quote($vars{'Content-Type'}));
    my $url = $dbrh->quote($vars{URLPrefix} . '/'. $vars{Bucket} . '/' . $vars{Key});
    my $s = $vars{'content_length'} + 0;
    BRDB::db_exec2($dbrh, "INSERT media_files (name,content_type,size,url,conference_id,user_id,created_at,updated_at) VALUES ($n,$ct,$s,$url,$c->{origin_id},(SELECT owner_id FROM conferences WHERE id=$c->{origin_id}),NOW(),NOW())", \$rows) or die;
    db_disconnect($dbrh);
    return ($rows==1);
}

# ---
sub end_move
{
    my $c = shift;
    my $rhost = shift;
    my $conffile = conference_path($c);
    my $mediapath = "$RECPATH/$conffile";
    my $fullpath = "$mediapath.xfer.progress";
    die if not client_up($rhost);
    print "GET [$fullpath]\n";
    $client->GET($fullpath);
    my $rc = $client->responseCode();
    if ($rc eq '404') {
        # progress file does not exist, progress, be patient
        # time limit?
        }
    elsif ($rc eq '200') {
        my $data = $client->responseContent();
        my %vars = ();
        foreach my $kv (split /\n/, $data) {
            print "s3[$kv]\n";
            $vars{$1} = $2 if $kv=~/^([^:]*):\s*(.*)$/ or $kv=~/^(.*)()$/;
            }
        if (defined $vars{Done}) {
            return undef if not create_media_record($c,$mediapath,\%vars);
            # if done, we have other interesting values also, i.e. etag etc. etc.
            return delete_files($rhost,$mediapath);
            }
        # progress file does not exists, but still uploading
        # time limit?
        }
    else {
        print STDERR $rhost . "->GET returned HTTP status $rc\n";
        }

    return undef;
}

# ---
sub get_conferences
{
    $conferences = [];
#    db_select("SELECT * FROM conferences WHERE state='media_ready' OR state='media_sync'",'conferences',$dbh) or die;
    db_select("SELECT c.id,c.fs_server,c.state,c.conference_key,c.origin_id,s.access FROM conferences c, systems s WHERE c.system_id = s.id AND (c.state='media_ready' OR c.state='media_sync')",'conferences',$dbh) or die;
    return $#{$conferences}+1;  # row count
}

# ---
sub process_conference_media
{
    my $c = shift;

    # ---
    my $rhost = $1 if $c->{fs_server}=~/ipv4=([^,]*)/;
    $rhost .= ":$1" if $c->{fs_server}=~/es_port=([^,]*)/;
    print "Processing conference [$c->{id}] on [$rhost] with files in state [$c->{state}]\n";

    # ---
    my $next_state = undef;
    if ($c->{state} eq 'media_ready') {
        $next_state =  start_move($c,$rhost);
        }
    elsif ($c->{state} eq 'media_sync') {
        $next_state = end_move($c,$rhost);
        }
    else {
        die;
        }
    return 0 if not $next_state;

    # -- don't progress state until we are done (files may be removed then)
    db_exec($dbh,"UPDATE conferences SET state='$next_state' WHERE id=$c->{id}",'_updated');
    return $_updated;
}

# ---
$dbh = db_quick_connect();

# ---
client_down;
s3_down;
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
{
    my $did_something = 0;

    # ---
    get_conferences();
    foreach my $c (@{$conferences}) {
        $did_something=1 if process_conference_media($c);
        }
    
    # ---
    if (not $did_something) {
        sleep $ENV{BR_SLEEP_LONG};
        client_down;
        s3_down;
        }
}

# ---
db_disconnect($dbh);

exit 0;

