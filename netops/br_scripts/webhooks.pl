#!/usr/bin/perl

# ---
#BR_description: Process incoming webhook requests
#BR_startup: running=always
#BR__END: 
# ---

$|++;
use XML::Simple qw(:strict);
use Data::Dumper;
use BRDB;
use BRConfig;

# ---
$rdsn=$dbruser=$dbrpass=$system_id=undef;
$dsn = $ENV{BR_DSN};
$dbuser = $ENV{BR_DBUSER};
$dbpass = $ENV{BR_DBPASS};

# ---
sub db_local_connect { $dbh = db_connect($dsn, $dbuser, $dbpass,'LOCAL'); }

# ---
sub update_provisioning_account
{
    my $code = shift;
    my $plan_code = shift;
    print "update_provisioning_account: code=$code, plan_code=$plan_code\n";
    if ($code =~ /^([A-Z])(\d+)-(\d+)$/) {
        my $system_type = $1;
        my $system_id = $2;
        my $account_id = $3;
        if (uc(substr($ENV{BR_ENVIRONMENT},0,1)) ne $system_type) {
            return 'wrong environment';
            }
        print "update_provisioning_account: system_type=$system_type, system_id=$system_id, account_id=$account_id\n";
        my $sd = BRConfig::get($dbh,$system_id,'provisioning');
        if (not defined $sd) {
            print STDERR "could not find or open active provisioning system with id=[$system_id]\n";
            print "could not find or open active provisioning system with id=[$system_id]\n";
            return undef;
            }
        print "connecting to provisioning system with access ..." . Dumper($sd) . "\n";
        my $dbrh = db_connect($sd->{dsn}, $sd->{dbuser}, $sd->{dbpass}, "$system_type-$system_id");
        if (not defined $dbrh) {
            print STDERR "could not open connection to provisioning system with id=[$system_id]\n";
            print "could not open connection to provisioning system with id=[$system_id]\n";
            return undef;
            }
        my $rows = undef;
        my $pc = $dbrh->quote($plan_code);
        BRDB::db_exec2($dbrh, "UPDATE accounts SET plan_code=$pc, plan_usage = NULL, plan_last_invoice = NULL, changing_flag=NULL, updated_at=NOW() WHERE id=$account_id", \$rows) or die;
        db_disconnect($dbrh);
        if (not $rows) {
            print STDERR "failed to update plan in provisioning system with id=[$system_id]\n";
            print "failed to update plan in provisioning system with id=[$system_id]\n";
            return undef;
            }
        return $rows;
        }
    else {
        print STDERR "cannot parse account code [$code]\n";
        print "cannot parse account code [$code]\n";
        return undef;
        }
}

# ---
sub process_webhook
{
    my $wh = shift;
    my $data = shift;
    print "wh=$wh\ndata=" . Dumper($data) . "\n";   # dump this always ... for debugging
    if (    ($wh eq 'new_subscription_notification') or
#            ($wh eq 'reactivated_account_notification') or
            ($wh eq 'updated_subscription_notification') or
            0 ) {
        if (update_provisioning_account($data->{account}->{account_code},$data->{subscription}->{plan}->{plan_code})) {
            return 'processed';
            }
        }
    elsif ( ($wh eq 'expired_subscription_notification') or
#            ($wh eq 'canceled_subscription_notification') or
            0 ) {
        if (update_provisioning_account($data->{account}->{account_code},undef)) {
            return 'processed';
            }
        }
    else {
        print "Marking webhook '$wh' ignored\n";
        return 'ignored';
        }
    return undef;
}

# ---
sub mark_progress
{
    my $id = shift;
    my $progress = shift;
    my $final_status = shift;
    $progress = $dbh->quote($progress);
    $final_status = $dbh->quote($final_status);
    die unless ($id+0)>0;
    my $rows;
    BRDB::db_exec2($dbh, "UPDATE webhooks SET progress=$progress, final_status=$final_status, updated_at=NOW() WHERE id=$id", \$rows) or die;
    return $rows;
}

# ---
sub process_webhooks
{
    my $did_something = 0;

    # ---
    my $data = undef;
    BRDB::db_select2("SELECT id,uri,body FROM webhooks WHERE final_status IS NULL ORDER BY created_at",\$data,$dbh);
    foreach $r(@{$data}) {
        print "[webhook] processing id = $r->{id}\n";
        my $xs = XMLin($r->{body}, ForceArray => 0, KeepRoot => 1, KeyAttr => [], NoAttr => 1);
        my $root = (keys %{$xs})[0];
        my $action = process_webhook($root,$xs->{$root});
        if (length($action)) {
            mark_progress($r->{id},'processed',$action) or die;
            $did_something = 1;
            }
        }
    return $did_something;
}

# ---
db_local_connect() or die;

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++)
{
    my $did_something = 0;
    $did_something = 1 if process_webhooks();
    sleep $ENV{BR_SLEEP_LONG} if not $did_something;
}

# ---
db_disconnect($dbh);

exit 0;

