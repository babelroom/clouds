#!/usr/bin/perl

# ---
#BR_description: Synchronize user data between netops and provisionging using DB
#BR_startup: foreach_provisioning=always
#BR__END: 
# ---

# --- DEPRECIATED ---
# -JR 1/2013 -- seems to haul a person back from netops person record to origin invitation and or user record(s)
# therefore no longer needed -- at some later point we'll re-visit activation emails

# ---
$|++;
use BRDB;
use String::Random;
use Data::Dumper;

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
$dsn = $ENV{BR_DSN};
$dbuser = $ENV{BR_DBUSER};
$dbpass = $ENV{BR_DBPASS};

# ---
$pat = new String::Random or die;

# ---
sub db_local_connect { $dbh = db_connect($dsn, $dbuser, $dbpass,'LOCAL'); }
sub db_remote_connect { $dbrh = db_connect($rdsn, $dbruser, $dbrpass,'REMOT'); }

# ---
sub get_new_people
{
    $new_people = [];
    # join people and conferences to get origin_conference_id
    db_select("SELECT p.id,p.name,p.last_name,p.dialout,p.email,p.pin,p.dialin,p.token,p.configuration AS role,p.updated_at,p.system_id,c.origin_id AS origin_conference_id,c.name AS conference_name,c.start FROM people p, conferences c WHERE p.system_id=$system_id AND p.is_deleted IS NULL AND p.origin_id IS NULL AND c.system_id=$system_id AND c.id=p.conference_id AND c.is_deleted IS NULL",'new_people',$dbh) or die;
    return $#{$new_people}>=0;
}

# ---
sub get_remote_users
{
    $remote_users = [];
#    %remote_email_map = ();
    my $emails = '';
    my $salts = '';
    foreach my $l(@{$new_people}) {
        $emails.=qq!,'$l->{email}'! if length $l->{email};
        $salts.=qq!,'$l->{token}'! if length $l->{token};
        }
    $emails = substr($emails,1);
    $salts = substr($salts,1);
    return if (!length($emails)) and (!length($salts));     # road to nowhere, not normally possible, but bad data got in once
    my $sql = "SELECT * FROM users WHERE ";
    $sql .= " (email_address IN (" . $emails . "))" if (length($emails));
    $sql .= " OR " if (length($emails)) and (length($salts));
    $sql .= " (salt IN (" . $salts . "))" if (length($salts));
    db_select($sql,'remote_users',$dbrh) or die;
    foreach my $r(@{$remote_users}) {
        foreach my $l(@{$new_people}) {
            if (    (length($r->{email_address})>0 && ($r->{email_address} eq $l->{email}))     or
                    ($r->{salt} eq $l->{token}) ) {
                $l->{rid} = $r->{id};
                $l->{timezone} = $r->{timezone};
                print "get_remote_users, matched ... [l]" . Dumper($l) . "\nwith [r]" . Dumper($r) . "\n";
                last;
                }
#        $remote_email_map{$r->{email_address}} = $r->{id};
            }
        }
}

# ---
sub invite_participant
{
    my $ouid = shift;   # origin user id, user id in front-end system
    my $l = shift;      # local person record

    # email!
    my $kv = '';
    foreach my $k (keys %{$l}) {
        my $v = $l->{$k};
        if ($k eq 'start') {
            if (defined $v) {
                $v .= ' GMT';
                }
            else {
                $v = 'anytime (standing)';
                }
            }
        $v =~ s/\n/\\n/g;
        $kv .= "$k=$v\n";
        }

    $kv .= "template=invite\n";
    $kv .= "ouid=$ouid\n";
    $kv .= "person_id=$l->{id}\n";

    # ---
    if (length($l->{email})) {
# disabling for now as not quite right
#        return 0 if not emails_generate_email_record($dbh,$dbrh,$system_id,$url_for_email,$kv);
        }

    # --- conference invitation
    my $pin = $dbrh->quote($l->{pin});
    my $dialin = $dbrh->quote($l->{dialin});
    my $role = $dbrh->quote($l->{role});
    my $token = $dbrh->quote($l->{token});
    db_exec($dbrh,"INSERT INTO invitations (pin,dialin,role,created_at,updated_at,conference_id,user_id,token) VALUES ($pin,$dialin,$role,NOW(),NOW(),$l->{origin_conference_id},$ouid,$token)",'_rows') or die;
    return 0 if $_rows<1;   # don't close out people record if invitation not set

    # done
    db_exec($dbh,"UPDATE people SET updated_at=NOW(), origin_id='$ouid' WHERE id=$l->{id} AND updated_at='$l->{updated_at}' AND is_deleted IS NULL AND origin_id IS NULL",'_rows') or die;
    return $_rows;
}

# ---
sub map_local_to_remote
{
    foreach my $l(@{$new_people}) {
#        my $rid = $remote_email_map{$l->{email}};
        my $rid = $l->{rid};
        if (defined $rid) {
            return invite_participant($rid,$l);
            }
#        else { # -- we need to be able to identify new user, don't actually expect this, but dirty data got in once ...
        elsif (length($l->{email}) or length($l->{token})) {
            my $salt = $l->{token}; 
            $salt = $pat->randregex("[a-zA-Z0-9]{40}") if not length($salt);
            $salt = $dbrh->quote($salt);
            my $em = $dbrh->quote($l->{email});
            my ($name, $last_name,$phone) = (($dbrh->quote($l->{name})), $dbrh->quote($l->{last_name}), $dbrh->quote($l->{dialout}));
            db_exec($dbrh,"INSERT INTO users (salt,name,last_name,phone,email_address,email,created_at,updated_at) VALUES ($salt,$name,$last_name,$phone,$em,$em,NOW(),NOW());",'_rows') or die;
            return $_rows;
            }
        }
}

# ---
db_remote_connect() or die;
db_local_connect() or die;

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
{
    my $did_something = 0;

    # ---
    if (get_new_people()) {
        get_remote_users();
        $did_something = 1 if map_local_to_remote();
        }

    # ---
# disabling this as emails are provided now via email_requests.pl job
#    $did_something = 1 if emails_send_activation_emails($dbh,$dbrh,$system_id,$url_for_email);

    sleep $ENV{BR_SLEEP_SHORT} if not $did_something;
}

# ---
db_disconnect($dbh);
db_disconnect($dbrh);

# ---
exit 0;
