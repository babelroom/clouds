#!/usr/bin/perl

# ---
#BR_description: Replicate from binlogs into message streams
#BR_startup: foreach_provisioning=always
#BR__END: 
# ---

# ---
$|++;
use BRDB;
use Data::Dumper;
use REST::Client;

# ---
$REPLICATE_DIR='../replicate_db';

# ---
$rdsn=$dbruser=$dbrpass=$system_id=undef;
foreach(split ',', $ENV{BR_PARAMETERS}){
    next if not /^(.*)=(.*)$/;
    $rdsn = $2 if $1 eq 'dsn';
    $dbruser = $2 if $1 eq 'dbuser';
    $dbrpass = $2 if $1 eq 'dbpass';
    $system_id = $2 if $1 eq 'system_id';
}

die if not defined $rdsn;
($_,$_,$rdbname,$rdbhost,$rdbport) = split /:/, $rdsn, 5;
die if not defined $rdbname or not defined $rdbhost or not defined $rdbport;

# ---
$dsn = $ENV{BR_DSN};
$dbuser = $ENV{BR_DBUSER};
$dbpass = $ENV{BR_DBPASS};

# ---
sub db_local_connect { $dbh = db_connect($dsn, $dbuser, $dbpass,'LOCAL'); }
sub db_remote_connect { $dbrh = db_connect($rdsn, $dbruser, $dbrpass,'REMOT'); }




# ---
# dynamically retrieve columns indexes from db ... much MUCH better than hardcoding the indexes here ...
# ---
sub field_index
{
    my ($table,$column) = @_;
    my $hash_name = "g__fields_${table}";
    if (not defined %$hash_name) {
        my $data = '';
        BRDB::db_select2("DESCRIBE $table", \$data, $dbrh) or die;
#print Dumper($data);
        %$hash_name = ();
#        %hash = %$hash_name;
        my $idx = 1;
        foreach my $r(@{$data}) {
            $$hash_name{$r->{'Field'}} = $idx;
            $idx++;
            }
#print Dumper(%$hash_name);
        }
    
    die "Unknown field '$column' in table '$table'" if not defined($$hash_name{$column});
    return $$hash_name{$column};
}

# ---
sub field_hashmap
{
    my $table = shift;
    #my @fields = shift;
    my @fields = @_;
    #my $fields = shift;
#print Dumper($table);
#print Dumper(@fields);
    my %hash = ();
    foreach my $field (@fields) {
        my $idx = field_index($table, $field);
#print "$idx -- $field\n";
        $hash{$idx} = $field;
        }
#print Dumper(%hash);
    return %hash;
}

# --- END of dynamic column index retrieval






# ---
$g_replicate_pos_file = undef;
$g_binlog_file = 'binlog.000001';
$g_last_binlog_file = undef;
$g_last_binlog_pos = undef;
$g_end_log_pos = undef;
sub clear_vars
{
    $g_verb = undef;
    @g_where = ();
    %g_where_md = ();
    @g_set = ();
    %g_set_md = ();
    $g_cursor = undef;
    $g_cursor_md = undef;
    $g_db = undef;
    $g_tbl = undef;
}

# ---
sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }
sub flush_binlog_pos
{
    my $pos;
    if (defined $g_end_log_pos) {
        $pos = $g_end_log_pos;
        }
    else {
        $pos = 4;
        }
    return if ($g_binlog_file eq $g_last_binlog_file) and ($pos<=$g_last_binlog_pos);
#print "binlog: writing [$g_binlog_file:$pos] to [$g_replicate_pos_file]\n";
    open FO, ">$g_replicate_pos_file";
    print FO "$g_binlog_file:$pos\n";
    close FO;
    $g_last_binlog_file = $g_binlog_file;
    $g_last_binlog_pos = $pos;
}

# ---
sub dump_query
{
    my $fh = shift;
    if ($g_verb eq 'delete') {
        print $fh "$g_verb ($g_tbl)[$g_where[1]] [$g_end_log_pos]\n";
        for(my $i=2; $i<=$#g_where; $i++) {
            my $s = $g_where[$i];
            my $md = $g_where_md{$i}; # type
            foreach my $key (keys %g_where_md) {
                next unless $key =~ /^$i-(.*)$/;
                $md .= " $1=$g_where_md{$key}";   # an attribute (is_null etc.)
                }
            print $fh "\t\@$i: [$s] {$md}\n";
            }
        }
    else {
        print $fh "$g_verb ($g_tbl)[$g_set[1]] [$g_end_log_pos]\n";
        for(my $i=2; $i<=$#g_set; $i++) {
            my $s = $g_set[$i];
            next if $s eq $g_where[$i];
            my $md = $g_set_md{$i}; # type
            foreach my $key (keys %g_set_md) {
                next unless $key =~ /^$i-(.*)$/;
                $md .= " $1=$g_set_md{$key}";   # an attribute (is_null etc.)
                }
            print $fh "\t\@$i: [$s] {$md}\n";
            }
        }
}

# ---
sub agdb
{
    # this is not very good and obviously a temporary fix
    # we have several race conditions where changes can't be propogated because certain rows / conferences haven't been setup yet
    # so we'll deal with this via a timed retry arrangement, obviously this will back everything up .. 
    # note: seems the original logic was written so as to handle multiple result rows for each db update trigger, so the !=0 logic
    # here doesn't jive with that
    my ($again_ref, $data_ref) = @_;
    return 0 if ($#{$$data_ref}>=0);
    $$again_ref++;
    if ($$again_ref>10) {
        my $msg = "reached maximal repeat count ... aborting\n";
        print $msg;
        print STDERR $msg;
        return 0;
        }
    print "again: $$again_ref: try again\n";
    sleep(2);
    return 1;
}

# ---
sub aght
{
    # this is not very good and obviously a temporary fix
    # we have several race conditions where changes can't be propogated because certain rows / conferences haven't been setup yet
    # so we'll deal with this via a timed retry arrangement, obviously this will back everything up .. 
    # note: seems the original logic was written so as to handle multiple result rows for each db update trigger, so the !=0 logic
    # here doesn't jive with that
    my ($again_ref, $rc) = @_;
    return 0 if $rc!=404;
    $$again_ref++;
    if ($$again_ref>10) {
        my $msg = "reached maximal repeat count ... aborting\n";
        print $msg;
        print STDERR $msg;
        return 0;
        }
    print "again: $$again_ref: try again\n";
    sleep(2);
    return 1;
}

# ---
sub changed
{
    my $idx = shift;
    my $null_key = "$idx-is_null";
    return 1 if ($g_set_md{$null_key} ne $g_where_md{$null_key});
    return 0 if ($g_set_md{$null_key} == 1);
    return 0 if ($g_set[$idx] eq $g_where[$idx]);
    return 1;
}

# ---
sub url_for_conference
{
    my $conference_id = shift;
    my $fs_server = shift;
    my ($hostname,$ipv4,$es_port) = (undef,undef,80);
    foreach(split ',', $fs_server){
        next if not /^(.*)=(.*)$/;
        $hostname = $2 if $1 eq 'hostname';
        $ipv4 = $2 if $1 eq 'ipv4';
        $es_port = $2 if $1 eq 'es_port';
        }
    return "http://$ipv4:$es_port/conference/$conference_id";
}

# ---
sub conference_urls_for_users
{
    my $arr_ref = shift;
    my $md_ref = shift;
    my $primary_key = $$arr_ref[1];
    my @results = ();
    my $_again=0; again:
    my $data = '';
    BRDB::db_select2("SELECT conference_id,fs_server FROM people WHERE system_id=$system_id AND origin_id=$primary_key AND fs_server IS NOT NULL", \$data, $dbh) or die;
    goto again if agdb(\$_again, \$data);
    foreach my $r(@{$data}) {
        push @results, url_for_conference($r->{conference_id}, $r->{fs_server});
        }
#print Dumper(@results); # currently debugging an interrmittant issue..
    return @results;
}

# ---
sub conference_urls_for_conferences
{
    my $arr_ref = shift;
    my $md_ref = shift;
    my $primary_key = $$arr_ref[1];
    my @results = ();
    my $_again=0; again:
    my $data = '';
    BRDB::db_select2("SELECT id,fs_server FROM conferences WHERE system_id=$system_id AND origin_id=$primary_key AND fs_server IS NOT NULL", \$data, $dbh) or die;
    goto again if agdb(\$_again, \$data);
    foreach my $r(@{$data}) {
        push @results, url_for_conference($r->{id}, $r->{fs_server});
        }
    return @results;
}

# ---
sub conference_urls_for_invitations
{
    my $arr_ref = shift;
    my $md_ref = shift;
    my $invitations_conference_id_idx = field_index('invitations','conference_id'); # probably 6 -- shouldn't this be global?
    my $primary_key = $$arr_ref[$invitations_conference_id_idx]; # conference_id
    return if (($$md_ref{"$invitations_conference_id_idx-is_null"})+0);
    my @results = ();
    my $_again=0; again:
    my $data = '';
    BRDB::db_select2("SELECT id,fs_server FROM conferences WHERE system_id=$system_id AND origin_id=$primary_key AND fs_server IS NOT NULL", \$data, $dbh) or die;
    goto again if agdb(\$_again, \$data);
    foreach my $r(@{$data}) {
        push @results, url_for_conference($r->{id}, $r->{fs_server});
        }
    return @results;
}

# ---
sub conference_urls_for_media_files
{
    my $arr_ref = shift;
    my $md_ref = shift;
    my $media_files_conference_id_idx = field_index('media_files','conference_id'); # probably 8 -- shouldn't this be global?
    my $primary_key = $$arr_ref[$media_files_conference_id_idx];
    return if (($$md_ref{"$media_files_conference_id_idx-is_null"})+0);
    my @results = ();
    my $_again=0; again:
    my $data = '';
    BRDB::db_select2("SELECT id,fs_server FROM conferences WHERE system_id=$system_id AND origin_id=$primary_key AND fs_server IS NOT NULL", \$data, $dbh) or die;
    goto again if agdb(\$_again, \$data);
    foreach my $r(@{$data}) {
        push @results, url_for_conference($r->{id}, $r->{fs_server});
        }
    return @results;
}

# ---
%g_binlog_numeric = (
    'INT' => 1,
);
sub bl_decode
{
    my $idx = shift;
    my $null_key = "$idx-is_null";
    return undef if $g_set_md{$null_key}>0;
    my $type = $g_set_md{$idx};
    my $v = $g_set[$idx];
    return ($v+0) if $g_binlog_numeric{$type};
    return $1 if $v=~/^'(.*)'$/;    # likely too simple
    return $v;
}

# --- TODO -- is this a hack? if we create the invitation records before the user records
# then we shouldn't need this -- right?
@g_users_columns = (name, last_name, phone, email_address, email, timezone, company, avatar_small, avatar_medium, avatar_large);
sub cascade_invitations_insert
{
    my $invitations_user_id_idx = field_index('invitations','user_id'); # probably 7 -- shouldn't this be global?
    my $id = $g_set[$invitations_user_id_idx];
    return () if ($g_set_md{"$invitations_user_id_idx-is_null"}>0) or ($id !~ /^(\d+)$/);
    my @users_events = ();
    my $data = '';
    my $sql = "SELECT " . join(",", @g_users_columns) . " FROM users WHERE id=$id";
    if (!BRDB::db_select2($sql, \$data, $dbrh)) {
        # db gone away?
        db_disconnect($dbrh);
        db_remote_connect();
        BRDB::db_select2($sql, \$data, $dbrh) or return ();
        }
    foreach my $r(@{$data}) {
        foreach my $col (@g_users_columns) {
            my $val = $r->{$col};
            push @users_events, "Kusers-$id-$col: $val" if defined $val;
            }
        }
    return @users_events;
}

# --- TODO -- ditto -- see comment above
sub cascade_invitations_delete
{
    my $invitations_user_id_idx = field_index('invitations','user_id'); # probably 7 -- shouldn't this be global?
    my $id = $g_where[$invitations_user_id_idx];
    return () if ($g_where_md{"$invitations_user_id_idx-is_null"}>0) or ($id !~ /^(\d+)$/);
    return ("Kusers-$id");
}

# ---
sub insert_or_update
{
    my $table = shift;
    my $primary_key = $g_set[1];
    my %map = %{"g_rowid_map_$table"};
    return undef if not defined %map;
    my @events = ();
    my @conferences = ();
    # add events
    foreach my $idx (keys %map) {
        my $colname = $map{$idx};
        if (changed($idx)) {
            my $val = bl_decode($idx);
            if (defined($val)) {
                push @events, "K$table-$primary_key-$colname: $val";
                }
            else {
                push @events, "K$table-$primary_key-$colname";
                }
            }
        }
    push @events, cascade_invitations_insert() if ($g_verb eq 'insert') and ($table eq 'invitations');   # TODO - hack?
    return undef if $#events<0;
    # add conferences
    my $fn = "conference_urls_for_$table";
    @conferences = &$fn(\@g_set,\%g_set_md) if defined (&$fn);
    return undef if $#conferences<0;
    my $client = REST::Client->new();
    die if not defined $client;
    foreach my $url (@conferences) {
        foreach my $event (@events) {
            print "[$url <-- $event]...";
# not sure why this was disabled ... but we do clearly need to support utf8
#            if ($event =~ /[^[:ascii:]]/) {
#                print STDERR "unsupported wide-characters in string, skipping\n";
#                next;
#                }
            my $_again=0; again:
            $client->PUT($url,$event);
            my $rc = $client->responseCode();
            print "[$rc]\n";
            goto again if aght(\$_again, $rc);
            }
        }
    $client = undef;
    return 1;
}

# ---
sub do_delete
{
    my $table = shift;
    my $primary_key = $g_where[1];
    my @events = ();
    my @conferences = ();
    # add events
    push @events, cascade_invitations_delete() if ($table eq 'invitations');   # TODO - hack?
    push @events, "K$table-$primary_key";
    # add conferences
    my $fn = "conference_urls_for_$table";
    @conferences = &$fn(\@g_where,\%g_where_md) if defined (&$fn);
    return undef if $#conferences<0;
    my $client = REST::Client->new();
    die if not defined $client;
    foreach my $url (@conferences) {
        foreach my $event (@events) {
            print "[$url <-- $event]...";
            # ... skip the again bit here
            $client->PUT($url,$event);
            my $rc = $client->responseCode();
            print "[$rc]\n";
            }
        }
    $client = undef;
    return 1;
}

# ---
sub process_query
{
    return undef if $g_db ne $rdbname;
    dump_query(STDOUT);
    if ($g_verb eq 'insert') {
        return undef if $#g_set<0;
        return insert_or_update($g_tbl);
        }
    elsif ($g_verb eq 'update') {
        return undef if $#g_set<0;
        return undef if $#g_where<0;
        return undef if ($g_where[1] ne $g_set[1]);    # TODO wierd change in primary keys -- what to do? -- does this even occur
        return insert_or_update($g_tbl);
        }
    elsif ($g_verb eq 'delete') {
        return undef if $#g_where<0;
        return do_delete($g_tbl);
        }
    die; # should not get here
    return undef;
}

# ---
sub do_desc
{
    $_ = shift;
    if (0) {
        }
    elsif (/^Rotate to\s+(\S+)\s+pos:\s*(\d+)/) {
        $g_binlog_file = $1;
        $g_end_log_pos = $2;
#        print "Rotate to file [$1], pos [$2]\n";
        }
    elsif (/^Xid\s*=\s*(\d+)/) {
        # good place to write the log pos
        flush_binlog_pos();
        }
}

# ---
sub do_row_md
{
    my ($rowid,$md) = @_;
    return unless $md =~ /^(\S+)\s+(.*)$/;
    $$g_cursor_md{$rowid} = $1;
    foreach my $item (split /\s+/, $2) {
        next unless $item =~ /^([\w|_]+)=(\d+)$/;
        $$g_cursor_md{"$rowid-$1"} = $2;
        }
}

# ---
sub do_log_pos
{
    $g_end_log_pos = shift;
#print STDERR "binlog: g_end_log_pos=$g_end_log_pos\n";
}

# ---
sub have_read_a_query {
    return 1 if $g_verb eq 'delete' and $#g_where>=0;
    return 1 if $#g_set>=0; # insert or update
    return 0;
}

# ---
sub process_result
{
    my $result = shift;
    my $did_something = undef;
    clear_vars();
    foreach(split /^/, $result) {
        chomp;
        my $l = $_;
    
#print STDERR "binlog: line[$_]\n";
        # --- execute any query being built to date
        if (have_read_a_query() && not $l=~/^###\s{3}@(\d+)=/) {
            $did_something = 1 if process_query();
            clear_vars();
            }

        # --- 
        if (0) {
            }
#691231 16:00:00 server id 23  end_log_pos 0    Rotate to binlog.000002  pos: 4
        elsif ($l=~/^#(\d{2})(\d{2})(\d{2})\s+(\d{1,2}):(\d{2}):(\d{2})\s+server\s+id\s+(\d+)\s+end_log_pos\s+(\d+)\s+(\S.*)$/) {
#            print "0 $1-$2-$3-$4-$5-$6 $7 $8 $9";
            my ($pos,$desc) = ($8,$9);
            do_desc($desc);    # have to do this first as "Rotate log" may clear the log pos list
            do_log_pos($pos) if $pos;
            }
        elsif ($l=~/^#\s+at\s+(\d+)/) {
#            print "1 $1 $2 $3 $4 $5-$6 $7 $8 $9";
            }
        elsif ($l=~/^# End of log file$/) {
            }
        elsif ($l=~/^### INSERT INTO\s(\w+)\.(\w+)$/) {
#            print "2.a $1 $2";
            $g_verb = 'insert';
            $g_db = $1;
            $g_tbl = $2;
            }
        elsif ($l=~/^### UPDATE (\w+)\.(\w+)$/) {
#            print "2.b $1 $2";
            $g_verb = 'update';
            $g_db = $1;
            $g_tbl = $2;
            }
        elsif ($l=~/^### DELETE FROM (\w+)\.(\w+)$/) {
#            print "2.c $1 $2";
            $g_verb = 'delete';
            $g_db = $1;
            $g_tbl = $2;
            }
        elsif ($l=~/^### SET$/) {
#            print "2.x";
            $g_cursor = \@g_set;
            $g_cursor_md = \%g_set_md;
            }
        elsif ($l=~/^### WHERE$/) {
#            print "2.y";
            $g_cursor = \@g_where;
            $g_cursor_md = \%g_where_md;
            }
        elsif ($l=~/^### (\S.*)$/) {
#            print "2.z $1";
            }
        elsif ($l=~/^###\s{3}@(\d+)=(.*)\s\/\*\s+(.*)\s+\*\/\s*$/) {
#            print "3 $1 $2 $3 $4 $5-$6 $7 $8 $9";
            $$g_cursor[$1] = $2;
            do_row_md($1,$3);
            }
        elsif ($l=~/^SET TIMESTAMP=(\d+)\D.*$/) {
#            print "4 $1";
            }
        elsif ($l=~/^BEGIN.*$/) {
#            print "5 [[begin]]";
#            clear_vars();
            }
        elsif ($l=~/^COMMIT.*$/) {
#            print "6 [[commit]]";
#            $did_something = 1 if process_query();
            }
        elsif ($l=~/^ROLLBACK.*$/) { }
        elsif ($l=~/^\/\*!(.*)\*\/;$/) { }
        elsif ($l=~/^SET\s+.*$/) { }
        elsif ($l=~/^DELIMITER\s+.*$/) { }
        else {
            print STDERR "unrecognized log line: [$l]\n";
            }
#        flush_binlog_pos();
#        print "\n";
#        if (defined($verb)) {
#            }
#        else {
#            }
#        print "$_\n";
    }

    $did_something = 1 if process_query();
    return $did_something;
}

# ---
sub do_log
{
    flush_binlog_pos() if not -r $g_replicate_pos_file;    # create initial file if it doesn't already exist
    die "can't write logpos file [$g_replicate_pos_file]" if not -r $g_replicate_pos_file;    # we gotta bail if we still don't have the file at this point
    open(FH,"<$g_replicate_pos_file");
    my $fc = <FH>;
    close FH;
    chomp $fc;
    my ($bl_file,$bl_pos) = split /:/, $fc;
    if (!defined($bl_file) or !defined($bl_pos)) {
        print STDERR "could not read valid binlog position from file [$g_replicate_pos_file]\n";
        return undef;
        }
    $g_binlog_file = $bl_file;
    $g_end_log_pos = $bl_pos;

    my $cmd="/usr/bin/mysqlbinlog -R -h $rdbhost -P $rdbport -d $rdbname --user=$dbruser --pass=$dbrpass --to-last-log -vv --base64-output=DECODE-ROWS --start-position=$g_end_log_pos $g_binlog_file";
#print STDERR "binlog, executing mysqlbinlog cmd: [$cmd]\n";
    my $result = `$cmd`;
#print STDERR "$result";
    return process_result($result);
}

# ---
db_remote_connect() or die;

#%g_rowid_map_users = ( 6 => name, 7 => email_address, 13 => last_name, 14 => timezone, 15 => company, 18 => phone, );
%g_rowid_map_users = field_hashmap('users',@g_users_columns);
#print Dumper(%g_rowid_map_users);
#%g_rowid_map_conferences = ( 2 => name, 16 => uri, 17 => skin_id, 18 => introduction, 19 => access_config, );
%g_rowid_map_conferences = field_hashmap('conferences', (name, uri, skin_id, introduction, access_config,) );
#%g_rowid_map_invitations = ( 2 => pin, 3 => role, 7 => user_id, );
%g_rowid_map_invitations = field_hashmap('invitations', (pin, role, user_id,) );
#%g_rowid_map_media_files = ( 2 => name, 4 => size, 5 => url, 9 => user_id, 14 => slideshow_pages, 15 => bucket, 16 => 'length', 17 => multipage );
%g_rowid_map_media_files = field_hashmap('media_files',(name, size, url, user_id, slideshow_pages, bucket, 'length', multipage,) );

db_local_connect() or die;

# ---
# TODO actually can't afford to exit this prog ...
$g_replicate_pos_file = "$REPLICATE_DIR" . '/provisioning_' . $system_id . '.binlog_pos';
#for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
for(my $it=0; 1; $it++) 
{
    my $did_something = 0;

    $did_something = 1 if do_log();

    sleep 1 if not $did_something;
}

# ---
db_disconnect($dbh);
db_disconnect($dbrh);

# ---
exit 0;
