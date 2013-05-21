package BRConfig;

# ---
use BRDB;
#require(Exporter);
#@ISA = qw(Exporter);
#@EXPORT = qw(emails_send_activation_emails emails_generate_email_record);

# ---
sub get
{
    my $handle = shift;
    my $id = shift;
    my $type = shift;
    my $key = shift;
    my $data;
    my $sql = "SELECT id,name,system_type,config_key,access FROM systems WHERE ";
    $sql .= "id=$id AND " if defined($id);
    $sql .= "system_type=" . $handle->quote($type) . " AND " if defined($type);
    $sql .= "config_key=" . $handle->quote($key) . " AND " if defined($key);
    $sql .= "TRUE";
    BRDB::db_select2($sql,\$data,$handle) or die;
    foreach $r(@{$data}) {
        my %vars = ();
        foreach $kv (split /,/, $r->{access}) {
            $vars{$1} = $2 if $kv=~/^([^=]*)=(.*)$/ or $kv=~/^(.+)()$/;
            }
        next if defined $vars{disabled};
        return \%vars;
        }
    return undef;
}

1;

