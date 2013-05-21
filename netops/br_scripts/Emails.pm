package Emails;

# ---
use BRDB;
use String::Random;
use Data::Dumper;
require(Exporter);
@ISA = qw(Exporter);
@EXPORT = qw(emails_send_activation_emails emails_generate_email_record);

# ---
sub internal_make_key
{
    if (not defined($pat)) {
        $pat = new String::Random or die;
        }
    return $pat->randregex("[a-zA-Z0-9]{40}")
}

# ---
sub emails_generate_email_record
{
    my $dbh = shift;
    my $dbrh = shift;
    my $system_id = shift;
    my $url_for_email = shift;
    my $kv = shift;
#print STDERR "kv=[$kv]\n";
    my %vars = ();
    foreach(split(/\n/, $kv)) {
        $vars{$1}=$2 if /^([^=]+)=(.*)$/;
        }
    
    # ---
    if (not length($vars{email})) {
        print STDERR "Emails: blank email address for record\n" . Dumper($kv);
        return 0;
        }

    # ---
    my $link_key = internal_make_key();
    $kv .= "link_key=$link_key\n";
    $kv .= "link_url=$url_for_email\n";
    my $link_key = $dbrh->quote($link_key);

    # --- create / update the token record on provisioning system
    my $rows = undef;
    if (defined $vars{erid}) {
        BRDB::db_exec2($dbrh, "UPDATE tokens SET link_key=$link_key WHERE id = $vars{erid} AND updated_at = '$vars{erua}'", \$rows) or die;
        }
    else {
        my $tm = $dbrh->quote($vars{template});
        BRDB::db_exec2($dbrh, "INSERT INTO tokens (template, link_key, expires, user_id) VALUES ($tm, $link_key, NULL, $vars{ouid})", \$rows) or die;
        }
    return 0 if $rows<1;    # not die?

    # --- create email record on netops system
    my ($em, $tm, $pid) = ($dbh->quote($vars{email}), $dbh->quote($vars{template}), $dbh->quote($vars{person_id}));
    $kv = $dbh->quote($kv);
#print STDERR "kv=[$kv]\n";
    $rows = undef;
    BRDB::db_exec2($dbh,"INSERT INTO emails (email,origin_id,template,kv_pairs,created_at,updated_at,system_id,person_id) VALUES ($em,$vars{ouid},$tm,$kv,NOW(),NOW(),$system_id,$pid)", \$rows) or die;
    return $rows;
}

# ---
sub emails_send_activation_emails
{
    my $dbh = shift;
    my $dbrh = shift;
    my $system_id = shift;
    my $url_for_email = shift;
    my $data=undef;
    BRDB::db_select2("SELECT t.id, t.template, t.updated_at, t.user_id, u.name AS first_name, CONCAT(u.name,' ',u.last_name) AS full_name, u.email, u.timezone FROM tokens t, users u WHERE t.is_deleted IS NULL AND t.link_key IS NULL AND u.id = t.user_id LIMIT 50", \$data,$dbrh) or die;
    my $did_something = 0;
    foreach my $r(@{$data}) {
        next if $r->{template} ne 'activate' and $r->{template} ne 'forgot_password';
        my $kv = "erid=$r->{id}\nerua=$r->{updated_at}\nemail=$r->{email}\nfirst_name=$r->{first_name}\nfull_name=$r->{full_name}\nouid=$r->{user_id}\ntemplate=$r->{template}\n";
        $did_something = 1 if emails_generate_email_record($dbh,$dbrh,$system_id,$url_for_email,$kv);
        }
    return $did_something;
}

1;
