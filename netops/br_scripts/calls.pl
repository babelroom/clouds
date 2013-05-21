#!/usr/bin/perl

# ---
#BR_description: Update call information - info and accounting
#BR_startup: foreach_provisioning=always
#BR__END: 
# ---

# ---
$|++;
use BRDB;
use URI::Escape;

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

# ---
sub db_local_connect { $dbh = db_connect($dsn, $dbuser, $dbpass,'LOCAL'); }
sub db_remote_connect { $dbrh = db_connect($rdsn, $dbruser, $dbrpass,'REMOT'); }

# --- some of these # are not currently in use as toll free, but are reserved for future use
%TOLLFREE = map { $_ => 1 } ( 800, 822, 833, 844, 855, 866, 877, 880 .. 889 );

# ---
sub accounting_code
{
    my $vars_ref = shift;
    my %vars = %$vars_ref;
# accounting_description === access === dialin# (regular, intl or toll-free), dialout / intl dialout / skype / gtalk / sip
    if ($vars{dialin} =~ /outbound/i) {
        return ($vars{ani} =~ /^\+?1(\d{3})\d{7}$/i) ? 'out' : 'outintl';
        }
    elsif ($vars{dialin} =~ /webcall/i) {
        return webcall;
        }
    elsif ($vars{dialin} =~ /^\+?1(\d{3})\d{7}$/i) {
        my $area_code = $1;
        return $TOLLFREE{$area_code} ? 'tollfree' : 'in';
        }
    else {
        return inintl;
        }
}

# ---
sub call_ended
{
    my $r = shift;
    my %vars = ();
    foreach my $kv (split /,/, $r->{meta_data}) {
        $vars{$1} = uri_unescape($2) if $kv=~/^([^=]*)=(.*)$/ or $kv=~/^(.+)()$/;
        }
    my $md = $dbrh->quote($r->{meta_data});
    my $ac = accounting_code(\%vars);
    my %acad_map = (
        in => '%s',
        inintl => 'Intl %s',
        out => 'Outbound Call',
        outintl => 'Intl Outbound Call',
        webcall => 'WebCall',
        tollfree => 'Toll-free %s',

        # --- later ...
        sip => 'SIP',
        skype_sip => 'Skype (SIP)',
        );
    my $ad = $dbrh->quote(sprintf($acad_map{$ac},$vars{dialin}));
    # notes - HD
    my @cs = split /:/, $vars{codec}, 6;
    my $notes = '';
# L16:16000:256000:G722:16000:64000
    if ((($cs[1]+0)>8000) and (($cs[4]+0)>8000)) {
        $notes = 'HD';
        }
    $notes = $dbrh->quote($notes);
    my $affected = 0;
    my $participant = $dbrh->quote($r->{full_name});
    $ac = $dbrh->quote($ac);
    my $ani = $dbrh->quote($vars{ani});
    print "row: $r->{id}, name: $r->{full_name}, destination: $dialout\n";


    # unfortunately we overlooked to set account_id correctly in conference and it's now the 11th hour... this is pretty solid ...
    #BRDB::db_exec2($dbrh, "INSERT INTO callees (participant,meta_data,created_at,updated_at,conference_id,started,ended,accounting_code,accounting_desc,notes,number,account_id) VALUES ($participant,$md,NOW(),NOW(),$r->{origin_conference_id},'$r->{started}','$r->{ended}',$ac,$ad,$notes,$ani,(SELECT account_id FROM conferences WHERE id=$r->{origin_conference_id}))", \$affected) or die;
    BRDB::db_exec2($dbrh, "INSERT INTO callees (participant,meta_data,created_at,updated_at,conference_id,started,ended,accounting_code,accounting_desc,notes,number,account_id) VALUES ($participant,$md,NOW(),NOW(),$r->{origin_conference_id},'$r->{started}','$r->{ended}',$ac,$ad,$notes,$ani,(SELECT a.id FROM users u, conferences c, accounts a WHERE c.owner_id=u.id AND a.owner_id=u.id AND c.id=$r->{origin_conference_id}))", \$affected) or die;

    if ($affected>0) {
        $affected = 0;
        print "row: $r->{id}: inserted into provisioning\n";
        BRDB::db_exec2($dbh, "UPDATE calls SET deployed_at=NOW(), updated_at=NOW() WHERE id=$r->{id}", \$affected) or die;
        print "row: $r->{id}: marked deployed\n" if ($affected);
        return $affected;
        }
    return 0;
}

# ---
sub update_call_information
{
    # ---
    # this logic can be changed to implement "real-time" nibble-style billing for in-progress calls by extending/modifying in the
    # following way
    #   - select records for in-progress calls by allowing r.ended==NULL
    #   - for those records an approximate measure of "call-time so far" is the difference between created_at and NOW()
    #   - push out to provisioning a "billing-adjustment" based off this approximate elapsed call-time
    #   - billing adjustments are calculated and pushed out every BR_SLEEP_LONG interval and replace any previous adjustment for that call
    #   - The running balance for an account is the actual balance with all billing adjusts applied
    #   - Once a call ends the billing adjustment is deleted and the actual cost is calculated and applied to the account balance.
    # ---
    my $data = '';
    # NOTE: we could just get the name from FS and avoid the join here, but not sure if we'll need future fields (origin user id??) from people
    BRDB::db_select2("SELECT r.id, r.started, r.ended, c.origin_id AS origin_conference_id, r.meta_data, CONCAT(p.name, ' ', p.last_name) AS full_name, p.origin_id AS user_id FROM calls r, conferences c, people p  WHERE r.conference_id=c.id AND r.deployed_at IS NULL AND r.ended IS NOT NULL AND c.is_deleted IS NULL AND c.system_id=$system_id AND r.person_id=p.id AND p.system_id=$system_id ORDER BY c.updated_at", \$data, $dbh) or die;
    foreach my $r(@{$data}) {
        call_ended($r);
        }
    return 0;
}

# ---
db_remote_connect() or die;
db_local_connect() or die;

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
{
    print "--------------------------------------------------------------------------------\n";
    print "New or modified calls for provisioning system $system_id\n";
    print "--------------------------------------------------------------------------------\n";

    update_call_information();

    # wait full timeout as we don't want to update billing for in-progress calls
    # too frequently
    sleep $ENV{BR_SLEEP_LONG};
    print "--------------------------------------------------------------------------------\n";
}

# ---
db_disconnect($dbh);
db_disconnect($dbrh);

exit 0;
