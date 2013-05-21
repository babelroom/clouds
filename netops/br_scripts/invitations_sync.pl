#!/usr/bin/perl

# ---
#BR_description: Synchronize invitation data between provisioning and netops people table
#BR_startup: foreach_provisioning=always
#BR__END: 
# ---

# ---
$|++;
use BRDB;
use Data::Dumper;
%conference_map = ();
$invitations = undef;

# ---
$rdsn=$dbruser=$dbrpass=$system_id=undef;
foreach(split ',', $ENV{BR_PARAMETERS}){
    next if not /^(.*)=(.*)$/;
    $rdsn = $2 if $1 eq 'dsn';
    $dbruser = $2 if $1 eq 'dbuser';
    $dbrpass = $2 if $1 eq 'dbpass';
    $system_id = $2 if $1 eq 'system_id';
#    $url_for_email = $2 if $1 eq 'url_for_email';
}

# ---
$dsn = $ENV{BR_DSN};
$dbuser = $ENV{BR_DBUSER};
$dbpass = $ENV{BR_DBPASS};

# ---
sub db_local_connect { $dbh = db_connect($dsn, $dbuser, $dbpass,'LOCAL'); }
sub db_remote_connect { $dbrh = db_connect($rdsn, $dbruser, $dbrpass,'REMOT'); }

# ---
sub get_new_or_updated_invitations
{
    $invitations = undef;
    my $sql = "SELECT i.id,u.name,u.last_name,u.phone,u.email,i.pin,i.role,i.conference_id,i.user_id,i.dialin,i.deployed_at,i.is_deleted FROM invitations i, users u WHERE i.user_id = u.id AND ((i.deployed_at IS NULL) OR (i.deployed_at<=i.updated_at))";
    BRDB::db_select2($sql,\$invitations,$dbrh) || die;
    # fixups
    foreach my $r(@{$invitations}) {
        $r->{role} = '' if not defined $r->{role};  # for backwards compat.
        }
    my @l = @{$invitations};
    return ($#l>=0) ? 1 : 0;
}

# ---
sub map_conferences
{
    my %ocids = ();
    foreach my $r(@{$invitations}) {
        $ocids{$r->{conference_id}} = 0;
        }
    my $sql = "SELECT id, origin_id FROM conferences WHERE origin_id IN (" . join(',', keys(%ocids)) . ")";
    %ocids = ();
    my $data = undef;
    BRDB::db_select2($sql,\$data,$dbh) || die;
    foreach my $r(@{$data}) {
        $ocids{$r->{origin_id}} = $r->{id};
        }
    foreach my $r(@{$invitations}) {
        $r->{netops_conference_id} = $ocids{$r->{conference_id}};
        }
}

# ---
sub new_people
{
    my @inserts = ();
    my @iids = ();
    my $count = 0;
    foreach my $r(@{$invitations}) {
        next if not defined $r->{netops_conference_id};
        next if defined $r->{deployed_at};
        push @iids, $r->{id};
        push @inserts, '('.$dbh->quote($r->{name}).','.$dbh->quote($r->{last_name}).','.$dbh->quote($r->{phone}).','.$dbh->quote($r->{dialin}).','.$dbh->quote($r->{role}).','.$dbh->quote($r->{email}).",$r->{netops_conference_id},NOW(),NOW(),".$dbh->quote($r->{user_id}).",$system_id,".$dbh->quote($r->{pin}).")";
        $count++;
        }
    return 0 if $#inserts<0;
    my $sql = 'INSERT INTO people (name,last_name,dialout,dialin,configuration,email,conference_id,created_at,updated_at,origin_id,system_id,pin) VALUES ' . join(',', @inserts);
    my $rows = undef;
    BRDB::db_exec2($dbh, $sql, \$rows) or die;
    die if $rows != $count;
    $sql = 'UPDATE invitations SET deployed_at = NOW() WHERE id IN (' . join(',', @iids) . ')';
    BRDB::db_exec2($dbrh, $sql, \$rows) or die;
    die if $rows != $count;
    return 1;
}

# ---
sub updated_people
{
    my $count = 0;
    foreach my $r(@{$invitations}) {
        next if not defined $r->{netops_conference_id};
        next if not defined $r->{deployed_at};
        next if not defined $r->{user_id};
        next if not defined $system_id; # for completeness
        my $sql = "UPDATE people SET "
            . "name=" . $dbh->quote($r->{name})
            . ", last_name=" . $dbh->quote($r->{last_name})
            . ", dialout=" . $dbh->quote($r->{phone})
            . ", dialin=" . $dbh->quote($r->{dialin})
            . ", configuration=" . $dbh->quote($r->{configuration})
            . ", email=" . $dbh->quote($r->{email})
            . ", pin=" . $dbh->quote($r->{pin})
            . ", is_deleted=" . $dbh->quote($r->{is_deleted})
#            . ", =" . $dbh->quote($r->{})
            . " , updated_at=NOW() WHERE system_id=$system_id AND conference_id=$r->{netops_conference_id} AND origin_id=$r->{user_id}";
        my $rows = undef;
        if (BRDB::db_exec2($dbh, $sql, \$rows) && $rows==1) {
            $sql = "UPDATE invitations SET deployed_at = NOW() WHERE id=$r->{id}";
            $count++ if BRDB::db_exec2($dbrh, $sql, \$rows);    # ignore error (at least for now ...), it'll get logged
            }
        #else ... continue to next entry on error ...
        }
    return $count>0;
}

# ---
db_remote_connect() or die;
db_local_connect() or die;

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
{
    my $did_something = 0;

    # --- 
    if (get_new_or_updated_invitations()) {
        map_conferences();
        $did_something = 1 if new_people();
        $did_something = 1 if updated_people();
        }

    sleep $ENV{BR_SLEEP_SHORT} if not $did_something;
}

# ---
db_disconnect($dbh);
db_disconnect($dbrh);

# ---
exit 0;
