#!/usr/bin/perl

# ---
#BR_description: Program to migrate media from a FS server once conference has completed
# **NB** the following causes scheduler.pl to whine endlessly
#BR_startup: running=manual
#BR__END: 
# ---

# ---
$|++;
use BRDB;
use BRJobs; # for job_launch in example 2
use REST::Client;
use URI::Escape;
use Data::Dumper;

# ---
#my $RECPATH = "/br_media/conf_recordings";  # physical and virtual are the same right now

# ---
#rhost=192.168.66.12:3001,cid=569,ts=1315255748373149,path=%2Fbr_media%2Fconf_recordings%2Fe8iIOmF2dsIhH3CV-000000000569-000.wav
$rhost=$cid=$ts=$path=undef;
foreach(split ',', $ENV{BR_PARAMETERS}){
    next if not /^(.*)=(.*)$/;
    $rhost = $2 if $1 eq 'rhost';
    $cid = $2 if $1 eq 'cid';
    $ts = $2 if $1 eq 'ts';
    $path = $2 if $1 eq 'path';
}

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
sub path_parse 
{
    my $p = shift;
    $p = uri_unescape($path);
    return ($1,$2) if $p =~ m|^(.*)/([^/]+)$|;
    return undef;
}
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
sub get_conference
{
    my $conference_id = shift;
    my $data;
    BRDB::db_select2("SELECT c.id,c.origin_id,s.access FROM conferences c, systems s WHERE c.system_id = s.id AND c.id = $conference_id",\$data,$dbh) or die;
    foreach $r(@{$data}) {
        return $r;
        }
    return undef;
}

# ---
sub start_move
{
#    my $c = shift;
#    my $rhost = shift;
#    my $conffile = conference_path($c);
#    my $fullpath = "$RECPATH/$conffile";
    my $fullpath = uri_unescape($path);
    my ($recpath,$conffile) = path_parse($path);
    die if not client_up($rhost);
    print "HEAD [$fullpath]\n";
    $client->HEAD($fullpath);
    my $rc = $client->responseCode();
    if ($rc eq '404') {
        # media file does not exist, progress
        print "media [$fullpath] not found for conference [$cid] on [$rhost]\n";
        return 0;
        }
    elsif ($rc eq '200') {
        return undef if not s3_up();
        my $data =<<__EOT__
AWSAccessKeyId: $s3_vars{AWSAccessKeyId}
AWSSecretAccessKey: $s3_vars{AWSSecretAccessKey}
Bucket: $s3_vars{Bucket}
URLPrefix: $s3_vars{URLPrefix}
Key: $conffile
Path: $recpath
File: $conffile
Content-Type: audio/x-wav

__EOT__
;
        $client->POST("$fullpath.xfer",$data);
        $rc = $client->responseCode();
        if ($rc ne '200') {
            print STDERR "failed to POST xfer data for media [$fullpath] not found for conference [$cid] on [$rhost]\n";
            return undef;
            }
        return 1;
        }
    else {
        print STDERR $rhost . "->HEAD returned HTTP status $rc\n";
        return -1;
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
    return 1;
}

# ---
sub create_media_record
{
    my $mediapath = shift;
    my $vars_ref = shift;
    my $dbrh = dbrh_open($conference_record->{access});
    return 0 unless $dbrh;
    my %vars = %$vars_ref;
    my ($n,$ct) = ($dbrh->quote($vars{Key}),$dbrh->quote($vars{'Content-Type'}));
    my $url = $dbrh->quote($vars{URLPrefix} . '/'. $vars{Bucket} . '/' . $vars{Key});
    my $s = $vars{'content_length'} + 0;
    my $len = $s;
    my $suffix = 'bytes';
    if ($len > 1024) {
        $len /= 1024;
        if ($len > 1024) {
            $len /= 1024;
            if ($len > 1024) {
                $len /= 1024;
                $suffix = 'GB';
                }
            else { $suffix = 'MB'; }
            }
        else { $suffix = 'KB'; }
        }
    $len = $dbrh->quote(sprintf("%.1f%s",$len,$suffix));
    BRDB::db_exec2($dbrh, "INSERT media_files (name,content_type,size,url,conference_id,bucket,length,user_id,created_at,updated_at) VALUES ($n,$ct,$s,$url,$conference_record->{origin_id},'Recordings',$len,(SELECT owner_id FROM conferences WHERE id=$conference_record->{origin_id}),NOW(),NOW())", \$rows) or die;
    db_disconnect($dbrh);
    return ($rows==1);
}

# ---
# 1 == success / done
# 0 == not ready yet
# -1 == error
sub end_move
{
#    my $c = shift;
#    my $rhost = shift;
#    my $conffile = conference_path($c);
#    my $mediapath = "$RECPATH/$conffile";
    #my ($recpath,$conffile) = path_parse($path);
    #my $mediapath = "$recpath/$conffile";
    my $mediapath = uri_unescape($path);
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
            return -1 if not create_media_record($mediapath,\%vars);
            # if done, we have other interesting values also, i.e. etag etc. etc.
            return delete_files($rhost,$mediapath);
            }
        # progress file does not exists, but still uploading
        # time limit?
        }
    else {
        print STDERR $rhost . "->GET returned HTTP status $rc\n";
        return -1;
        }

    return 0;
}

# ---
$dbh = db_quick_connect();

client_down;
s3_down;

# ---
$conference_record = get_conference($cid);
die if not defined $conference_record;

# --- start transfer
my $result = start_move();
exit $result if $result < 1;

# ---
for(my $i=0; $i<40; $i++) {
    $result = end_move();
    if ($result) {
        last;
        }
    else {
        # simple exponential backoff
        my $delay = 10 + (2 << $i);
        $delay = 7200 if $delay>7200;
        print "Not ready, backing off for [$delay] seconds\n";
        sleep $delay;
        }
}

db_disconnect($dbh);

exit 0;

