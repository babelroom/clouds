package BRDB;

# ---
use DBI;
require(Exporter);  # not needed if not exporting fns
@ISA = qw(Exporter);
@EXPORT = qw(db_connect db_quick_connect db_disconnect db_exec db_select);

# ---
%handhash = ();

# ---
sub tme { return scalar(localtime)." "; }

# ---
sub db_connect
{
    my $dsn = shift;
    my $dbuser = shift;
    my $dbpass = shift;
    my $name = shift;
    my $handle;
    my %attr = ( PrintError => 0, RaiseError => 0 ,); #-- ignored -- useless
#    $handle = DBI->connect($dsn, $dbuser, $dbpass, \%attr);
    $handle = DBI->connect($dsn, $dbuser, $dbpass)
        or (warn "DB: connect failed: $DBI::errstr\n" and return 0);
    $handle->do("SET TIME_ZONE = '+0:00'") if $handle;   # deal with time in UTC
#    $handle->{'mysql_enable_utf8'} = 1;    --- definitely seems to actually >>cause<< problems ...
    $handle->do("SET NAMES utf8") if $handle;   # deal with time in UTC
    $handhash{$handle} = $name;
    return $handle;
}

# ---
sub db_quick_connect
{
    return db_connect($ENV{BR_DSN},$ENV{BR_DBUSER},$ENV{BR_DBPASS},'LOCAL');
}

# ---
sub db_disconnect
{
    my $handle = shift;
    print "SQL{$handhash{$handle}}: Disconnect\n";
    $handle->disconnect
        or warn "DB: disconnect failed: $DBI::errstr\n";
}

## ---
#sub db_exec
#{
#    my $handle = shift;
#    my $sql = shift;
#    my $rows_var = shift;
#    print tme()."SQL{$handhash{$handle}}: [$sql]\n";
#    my $stmt = $handle->prepare($sql);
#    if ($stmt->execute()) {
#        my $cnt = $stmt->rows;
#        print tme()."SQL{$handhash{$handle}}: OK [$cnt rows affected]\n";
#        ${"main::$rows_var"} = $cnt if defined $rows_var;
#        $stmt->finish();
#        return 1;
#        }
#    else {
#        warn "DB: execute failed: $DBI::errstr [$sql]\n";
#        $stmt->finish();
#        return 0;
#        }
#}

# ---
sub db_exec
{
    my $handle = shift;
    my $sql = shift;
    my $rows_var = shift;
    my $var = undef;
    my $result = db_exec2($handle, $sql, \$var);
    ${"main::$rows_var"} = $var if $result==1 and defined $rows_var;
    return $result;
}

# ---
sub db_exec2
{
    my $handle = shift;
    my $sql = shift;
    my $rows_var = shift;
    my $insertid_var = shift;
    print tme()."SQL{$handhash{$handle}}: [$sql]\n";
    my $stmt = $handle->prepare($sql);
    if ($stmt->execute()) {
        my $cnt = $stmt->rows;
        print tme()."SQL{$handhash{$handle}}: OK [$cnt rows affected]\n";
        $$rows_var = $cnt if defined $rows_var;
        $$insertid_var = $stmt->{mysql_insertid} if defined $insertid_var;
        $stmt->finish();
        return 1;
        }
    else {
        warn "DB: execute failed: $DBI::errstr [$sql]\n";
        $stmt->finish();
        return 0;
        }
}

# ---
sub db_select
{
    my $sql = shift;
    my $result_var = shift;
    my $handle = shift;
    print tme()."SQL{$handhash{$handle}}: [$sql]\n";
    my $stmt = $handle->prepare($sql);
    if (not defined $stmt->execute()) {
        warn "DB: execute failed: $DBI::errstr [$sql]\n";
        return 0;
        }
    my $result = 0;
    ${"main::$result_var"} = [];
    my $c = $stmt->rows;
    while(my(@data)=$stmt->fetchrow_array) {
        my $d;
        my $i=0;
        my %h = ();
        foreach $d (@data) {
            $h{$stmt->{NAME}->[$i++]}=$d;
            }
        push(@{${"main::$result_var"}}, \%h);
        }
    print tme()."SQL{$handhash{$handle}}: [$c rows]\n";
    $stmt->finish();
    return 1;
}

# ---
sub db_select2
{
    my $sql = shift;
    my $result_var = shift;
    my $handle = shift;
    print tme()."SQL{$handhash{$handle}}: [$sql]\n";
    my $stmt = $handle->prepare($sql);
    if (not defined $stmt->execute()) {
        warn "DB: execute failed: $DBI::errstr [$sql]\n";
        return 0;
        }
    my $result = 0;
    $$result_var = [];
    my $c = $stmt->rows;
    while(my(@data)=$stmt->fetchrow_array) {
        my $d;
        my $i=0;
        my %h = ();
        foreach $d (@data) {
            $h{$stmt->{NAME}->[$i++]}=$d;
            }
        push(@{$$result_var}, \%h);
        }
    print tme()."SQL{$handhash{$handle}}: [$c rows]\n";
    $stmt->finish();
    return 1;
}

1;

