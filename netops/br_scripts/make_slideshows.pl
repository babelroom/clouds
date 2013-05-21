#!/usr/bin/perl

# possibly rename away from make slideshows to something more generally about processing files

# ---
#BR_description: Create slideshows from other file formats on provisioning systems
#BR_startup: foreach_provisioning=always
#BR__END: 
# ---

# ---
$|++;
use BRDB;
use Amazon::S3;
use String::Random;
use Data::Dumper;   # tmp;

# ---
$pat = new String::Random or die;
$wget = "/usr/bin/wget";
$file = "/usr/bin/file";
$dsn = $ENV{BR_DSN};
$dbuser = $ENV{BR_DBUSER};
$dbpass = $ENV{BR_DBPASS};
%g_s3_vars = ();
$g_s3 = undef;

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
sub db_local_connect { $dbh = db_connect($dsn, $dbuser, $dbpass,'LOCAL'); }
sub db_remote_connect { $dbrh = db_connect($rdsn, $dbruser, $dbrpass,'REMOT'); }

# ---
sub s3_down         { %g_s3_vars = (); }
sub s3_up
{
    return 1 if defined $g_s3_vars{_};
    my $data;
    BRDB::db_select2("SELECT access FROM systems WHERE system_type LIKE '%s3%'",\$data,$dbh) or die;
    foreach $r(@{$data}) {
        %vars = ();
        foreach $kv (split /,/, $r->{access}) {
            $vars{$1} = $2 if $kv=~/^([^=]*)=(.*)$/ or $kv=~/^(.*)()$/;
            }
        next if defined $vars{disabled};
        %g_s3_vars = %vars;
        $g_s3_vars{_} = '';
        return 1;
        }
    print STDERR "no s3 storage configuration found\n";
    return 0;
}

# ---
sub get_unprocessed_media
{
    my $file_ref = shift;
    my $data;
    BRDB::db_select2("SELECT * FROM media_files WHERE slideshow_pages IS NULL ORDER BY updated_at LIMIT 1", \$data, $dbrh) or die;
    return undef if $#{$data};  # should get 1 row
    return $$file_ref = ${$data}[0];
}

# ---
sub convert_a_page
{
    my $master_url = shift;
    my $page = shift;
    my $tmpfile = shift;
    
    print "convert_a_page: master_url=$master_url, page=$page, tmpfile=$tmpfile\n";
#    # tmp. (to throttle conversion)
#    if ($page>4) {
#        print "convert_a_page: no page $page => file conversion is done\n";
#        return 0;
#        }
##    `cp ./foo.png $tmpfile`;

    my $url = $master_url;
    $url =~ s/\?(\d+)$//;
    #$url = uri_escape($url); # TODO use URI::Escape if needed, apparently not needed for now
    print "convert_a_page: url=[$url]\n";
    #my $cmd = "$wget -qO $tmpfile 'http://docs.google.com/viewer?url=" . $url . "&a=bi&pagenumber=$page&w=600'";
    my $cmd = "$wget -qO $tmpfile 'http://docs.google.com/viewer?url=" . $url . "&a=bi&pagenumber=$page&w=800'";
    print "convert_a_page: cmd=[$cmd]\n";

    # $rc==-2, non-fatal error, can retry this document
    # $rc==-3, non-fatal error, don't retry this document (treat as unconvertible, i.e. converted 0 pages)

    my $rc = system($cmd);
    print "convert_a_page: rc=[$rc]\n";
# this is what happens when the document is done, therefore return 0 (at least for the present) TODO (re-evaluate)
    return 0 if $rc; # I've seen rc 256 and 2048 here to indicate EOF

    return -3 if $rc;

    print "convert_a_page: converted rc=[$rc]\n";
    if (not -f $tmpfile) {
        print "convert_a_page: internal error, $tmpfile not a regular file\n";
        return -3;
        }

    print "convert_a_page: determining file type of result\n";
    my $type = `$file -b $tmpfile`;
    print "convert_a_page: result=[$type]\n";
    if ($type =~ /^PNG/) {
        print "convert_a_page: $tmpfile has type PNG - good!\n";
        return 1;
        }

    print "convert_a_page: Unexpected result file type [$tmpfile]\n";
    return 0;
}

# ---
sub s3_err
{
    my $b = shift;
    print "Msg: an s3 error occurred $!\n";
    if (defined $b) {
        print "b_err: $b->err\n";
        print STDERR "b_err: $b->err\n";
        print "b_errstr: $b->errstr\n";
        print STDERR "b_errstr: $b->errstr\n";
        }
    return -1;
}

# --- return 1==OK, -1 error
sub upload_file
{
    my $key = shift;
    my $bucket = shift;
    my $file = shift;
    print "upload_page: key=$key\n";

    # --- get s3 configuration
    if (not defined $g_s3) {
        return -1 if not s3_up();
        die if not defined %g_s3_vars;
        print "upload_page: connecting to s3\n";
        $g_s3 = Amazon::S3->new({
            aws_access_key_id     => $g_s3_vars{AWSAccessKeyId},
            aws_secret_access_key => $g_s3_vars{AWSSecretAccessKey}
            });
        return s3_err(undef) if not defined $g_s3;
        print "upload_page: connected to s3\n";
        }
    die if not defined $g_s3;
    print "upload_page: opening bucket: $bucket\n";
    my $b = $g_s3->bucket($bucket);
    return s3_err($b) if not defined $b;
    print "upload_page: opened bucket: $bucket\n";
#$fullpath = $vars{Path};
#$fullpath .= '/' . $vars{File};
    print "upload_page: add_key_filename(key => $key, file => $file)\n";
    my $result = $b->add_key_filename(
        $key, $file,{
            content_type => 'image/png',
            });
    return s3_err($b) if not defined $result;
    print "upload_page: add_key_filename: done!\n";
    $result = $b->set_acl({
        key => $key,
        acl_short => 'public-read',
        });
    return s3_err($b) if not defined $result;
    print "upload_page: set_acl: done!\n";

#err if not defined $result;
#$result = $b->head_key($vars{Key});
$result = $b->head_key($key);
#err if not defined $result;
print "2=============: K/V Pairs from s3\n";
foreach my $k (keys %$result) {
    print "$k: $result->{$k}\n";
}

    return 1;
}

# ---
sub upload_page
{
    my $master_url = shift;
    my $page = shift;
    my $tmpfile = shift;

    # ---
    print "upload_page: master_url=$master_url, page=$page, tmpfile=$tmpfile\n";
    my $key = $master_url;
    $key =~ s/.*\/([^\/]+)$/$1/;
    $key =~ s/\?\d*$//;
    $key =~ tr/./_/;
    $key .= "-${page}.png";

    return upload_file($key, 'bblr-uploads', $tmpfile);
}

# ---
sub convert_compound_file
{
    my $f = shift;
    print "convert_compound_file: entering with file [$f->{id}, $f->{name}]\n";
    my $page = 1;
    my $tmpfile = "/tmp/make_slideshow.$$.tmp";
    my $rc=undef;
    my $converted = 0;
    for(;;) {
        $rc =  convert_a_page($f->{url}, $page, $tmpfile);
        last if $rc != 1;
        $converted = 1;
        $rc = upload_page($f->{url}, $page, $tmpfile);
        last if $rc != 1;
        $page++;
        }
    $page--;
    if ($converted) {
        $f->{multipage} = 1;
        }
    else {
        print "convert_compound_file: not converted\n";
        if ($f->{content_type} =~ /^image\/(.*)$/) {
            print "convert_compound_file: setting as single image of type [$1]\n";
            $page = 1;
            }
        }
    # one way or the other, we are done with $tmpfile
    unlink($tmpfile);
    %g_s3_vars = ();
    $g_s3 = undef;
    print "convert_compound_file: returning with rc=$rc\n";
    return $rc if $rc;
    if (!$page) {
        }
    $f->{length} = "$page " . ($page==1 ? 'page' : 'pages');
    return $page;
}

# ---
sub file_info
{
    my $path = shift;
    my $cmd = "/usr/bin/identify -verbose $path";
    my @output = `$cmd`;
    my %hash = ();
    foreach my $line (@output) {
        my ($key, $value) = split /:\s*/, $line, 2;
        $key =~ s/^(\s*)(\S.*)$/$2/;
        $hash{$key} = $value;
        }
print Dumper(%hash);
    return %hash;
}

# ---
sub generate_avatar
{
    my ($f, $tmpfile, $field, $width, $height) = @_;
    my $subtmp = "${tmpfile}-${field}";
    my $cmd = "/usr/bin/convert $tmpfile -resize ${width}x${height} $subtmp";
    my $rc = system($cmd);
    print "generate_avatar: cmd=[$cmd], rc=[$rc]\n";
    return -3 if $rc;
    my ($key, $subdir) = ($pat->randregex("[0-9a-z]{20}"), 'bblr-avatars');
    my %info = file_info($subtmp);
    if (defined $info{'Format'}) {
        $key .= '.'.(split /\s+/, lc($info{'Format'}))[0];
        }
    $rc = upload_file($key,$subdir,$subtmp);   # returns 1 on success
    unlink($subtmp);
    return -1 if ($rc<0);

    my ($rows,$url) = (undef, $dbrh->quote("//$subdir.s3.amazonaws.com/$key"),);
    BRDB::db_exec2($dbrh, "UPDATE users SET `$field`=$url, updated_at=NOW() WHERE id=$f->{user_id}", \$rows) or die;
    return -1 if ($rows!=1);

    return 0;
}

# ---
sub process_avatar_file
{
    my ($f, $tmpfile) = @_;
    # get the mime-type only this way:
    # file -b --mime-type $tmpfile
    my $rc = 0; # no error, no slideshow pages converted
    $rc=-3 if generate_avatar($f,$tmpfile,'avatar_large', 640,480);
    $rc=-3 if generate_avatar($f,$tmpfile,'avatar_medium', 214,160);
    $rc=-3 if generate_avatar($f,$tmpfile,'avatar_small', 50,50);
    return $rc;
}

# ---
sub process_avatar
{
    my $f = shift;
    my $tmpfile = "/tmp/avatar.$$.tmp";
    my $cmd = "$wget -qO $tmpfile '$f->{upload_url}'";
    print "process_avatar: cmd=[$cmd]\n";
    my $rc = system($cmd);
    print "process_avatar: rc=[$rc]\n";
    return -3 if $rc;   # give up on this conversion, but don't retry

    # now we have the master avatar file locally
    $rc = process_avatar_file($f,$tmpfile);
    unlink($tmpfile);

    return $rc;   # no error, no slideshow pages converted
}

# ---
sub convert_file
{
    my $f = shift;
    print "convert_file: entering with file [$f->{id}, $f->{name}]\n";
    if (not (defined $f->{url}) and (defined $f->{upload_url}) and (defined $f->{user_id}) and ($f->{bucket} eq 'Avatar')) {
        return process_avatar($f);
        }
    else {
        # default
        return convert_compound_file($f);
        }
}

# ---
sub update_file_record
{
    my $f = shift;
    my $pages = shift;
    
    my ($rows,$mp,$len) = (undef, $dbrh->quote($f->{multipage}), $dbrh->quote($f->{length}));
    BRDB::db_exec2($dbrh, "UPDATE media_files SET slideshow_pages=$pages, multipage=$mp, length=$len, updated_at=NOW() WHERE id=$f->{id}", \$rows) or die;
    return ($rows==1);
}

# ---
sub process_file
{
    my $f = shift;
    my %hash = %$f;

    print "Processing the following file:\n";
    foreach my $k (keys %hash) {
        print "\t$k => [$hash{$k}]\n";
        }

    # marking conversion as in progress (-1)
    die if not update_file_record($f,-1);

    my $rc = convert_file($f);
    # $rc==-1, fatal error, log and quit
    # $rc==-2, non-fatal error, can retry this document
    # $rc==-3, non-fatal error, don't retry this document (treat as unconvertible, i.e. converted 0 pages)
    # otherwise, $rc is the # pages converted
    if ($rc<0) {
        print STDERR "process_file: error, rc=$rc\n";
        exit -1 if $rc==-1;
        return -1 if $rc==-2;
        die if $rc!=-3;
        $rc = 0;    # $rc==-3
        }

    # $rc < 0 serious error h
    # $rc == 0 .. no error, but documented converko 
    return update_file_record($f,$rc);
}

# ---
db_remote_connect() or die;
db_local_connect() or die;

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
{
    my $did_something = 0;

    # --- 
    my $file = undef;
    if (get_unprocessed_media(\$file)) {
        process_file($file);
        $did_something = 1;
        }

    # --
    sleep $ENV{BR_SLEEP_SHORT} if not $did_something;
}

# ---
db_disconnect($dbh);
db_disconnect($dbrh);

# ---
exit 0;

