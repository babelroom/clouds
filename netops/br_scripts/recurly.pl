#!/usr/bin/perl

# ---
#BR_description: Synchronize account/billing data between provisioning and recurly
#BR_startup: foreach_provisioning=always
#BR__END: 
# ---

$|++;
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple qw(:strict);
use Data::Dumper;
use Encode;
use BRDB;
use BRConfig;
use BRRate;

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
%cached_plans = ();

# ---
sub db_local_connect { $dbh = db_connect($dsn, $dbuser, $dbpass,'LOCAL'); }
sub db_remote_connect { $dbrh = db_connect($rdsn, $dbruser, $dbrpass,'REMOT'); }

# ---
sub open_recurly_request
{
    my $method = shift;
    my $uri = shift;
    my $varsref = shift;
    my $data;
    my $vars = BRConfig::get($dbh,undef,'recurly');
    if (not defined $vars) {
        print "No recurly configuration!\n";
        print STDERR "No recurly configuration!\n";
        return undef;
        }
    my $req = HTTP::Request->new($method => "$vars->{url}$uri");
    $req->header('Accept' => 'application/xml');
    $req->header('Content-Type' => 'application/xml; charset=utf-8');
    $req->authorization_basic($vars->{auth_user},$vars->{auth_pass});
    $$varsref = $vars;
    return $req;
}

# ---
sub get_last_invoice
{
    my $account_code = shift;
    my $vars = undef;
    my $req = open_recurly_request(GET,"accounts/$account_code/invoices",\$vars);
    return undef if not defined $req;
    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);
    if ($res->is_success) {
#        print STDERR Dumper($res);
        my $xs = XMLin($res->decoded_content, ForceArray => ['invoice'], KeyAttr => '__dummy__', NoAttr => 1);
        my $highest_invoice = -1;
        foreach my $i (@{$xs->{invoice}}) {
            my $in = (($i->{invoice_number})+0);
            if ($highest_invoice < $in) {
                $highest_invoice = $in;
                }
            }
        return ($highest_invoice>-1) ? "$highest_invoice" : "";
        }
    else {
        print STDERR Dumper($res);
        return undef;
        }
}

# ---
sub do_new_accounts
{
    my $did_something = 0;

    # ---
    my $data;
    BRDB::db_select2("SELECT a.id,u.name,u.last_name,u.email_address,u.email FROM accounts a,users u WHERE a.owner_id=u.id AND a.external_code IS NULL",\$data,$dbrh);
    foreach $r(@{$data}) {
        print "[new account] processing id = $r->{id}\n";
        my $vars = undef;
        my $req = open_recurly_request(POST,'accounts',\$vars);
        last if not defined $req;
        my $ua = LWP::UserAgent->new;
        my $account_code = $vars->{account_prefix} . $system_id . '-' . $r->{id};
        my $ref = {
            'account' => {
                account_code => $account_code,
                accept_language => 'en-us,en;q=0.5',
                username => $r->{email_address},
                email => $r->{email},
                first_name => $r->{name},
                last_name => $r->{last_name},
                company_name => $r->{company}
                }
            };
        my $xml =  XMLout($ref, KeyAttr => 'account', AttrIndent => 1, KeepRoot => 1, NoAttr => 1, XMLDecl => "<?xml version='1.0' standalone='yes' encoding='UTF-8'?>");
#        eval {  # perl 5.10
            $req->add_content_utf8($xml);
#print "5.10 ...\n" . Dumper($req);
#            1;
#            }
#        or do { # perl 5.8.8
#            $req->content($xml);
#print "5.8.8 ...\n" . Dumper($req);
#            };
        my $res = $ua->request($req);
        print "dumping result ...\n" . Dumper($res);
        if ($res->code()==422) {
            # --- if we failed because account already exists, then pull it 
            my $xs = XMLin($res->decoded_content, ForceArray => 0, KeyAttr => 'account');
            if ($xs->{error}->{field} eq 'account_code' and $xs->{error}->{code} eq 'taken') {
                print "Account already taken, GET account ....\n";
                $vars = undef;  # not really needed
                $req = open_recurly_request(GET,"accounts/$account_code",\$vars);
                last if not defined $req;
                $res = $ua->request($req);
                if (not $res->is_success()) {
                    print STDERR "Account GET failed\n";
                    print STDERR Dumper($res);
                    }
                }
            }
        # -- NB at this point we are examing the results of either the initial query (create account)
        # -- or the subsequent GET account
        if ($res->is_success) {
            my $xs = XMLin($res->decoded_content, ForceArray => 0, KeyAttr => 'account', NoAttr => 1);
            print "hosted_login_token => $xs->{hosted_login_token}\n";
            my $code = $dbrh->quote($account_code);
            my $hlt = $dbrh->quote($xs->{hosted_login_token});
            my $rows;
            BRDB::db_exec2($dbrh, "UPDATE accounts SET external_code=$code,external_token=$hlt,changing_flag=NULL,updated_at=NOW() WHERE id=$r->{id}", \$rows) or die;
            $did_something = 1;
            }
        else {
            print STDERR "recurly REST API Error: " . $res->status_line . ": (id=$r->{id}); Dumping...\n";
            print STDERR Dumper($res);
            }
        }

    return $did_something;
}

# ---
sub get_plan
{
    my $plan_code = shift;
    if (not defined $plan_code) {
        print STDERR "get_plan(): NULL plan code!\n";
        print "get_plan(): NULL plan code!\n";
        return undef;
        }
    my $plan_data = $cached_plans{$plan_code};
    return $plan_data if defined $plan_data;
    my $plan_data = BRConfig::get($dbh,undef,'plans',$plan_code);
    if (not defined $plan_data) {
        print "No plan data for '$plan_code'!\n";
        print STDERR "No plan data for '$plan_code'!\n";
        return undef;
        }
#print STDERR Dumper($vars);
#    $plan_data = $vars->{access};
    $cached_plans{$plan_code} = $plan_data;
    return $plan_data;
}

# ---
sub rate_calc
{
    my $r = shift;
    print "looking up plan, then rating record...\n" . Dumper($r);
    if (not defined $r->{plan_code}) {
        print STDERR "get_plan(): NULL plan code from record:\n" . Dumper($r);
        print "get_plan(): NULL plan code from record:\n" . Dumper($r);
        die;
        }
    $plan_data = get_plan($r->{plan_code});
    die "no plan data configured for plan_code '$r->{plan_code}'" if not defined $plan_data;
    return BRRate::rate($plan_data,$r->{accounting_code},$r->{accounting_desc}, $r->{started},$r->{number},$r->{seconds},$r->{plan_usage});
}

# ---
sub charge_or_credit
{
    my ($r,$amount_in_cents,$description) = @_;
    $amount_in_cents = ($amount_in_cents)+0;    # make sure it's numeric

    print "[new charge/credit] processing id = $r->{id}\n";
    my $vars = undef;
    my $charge_or_credit = ($amount_in_cents<0) ? 'credit' : 'charge';
    my $req = open_recurly_request(POST,"accounts/$r->{external_code}/${charge_or_credit}s",\$vars);
    return undef if not defined $req;
    my $ua = LWP::UserAgent->new;
    my $ref = {
        $charge_or_credit => {
            amount_in_cents => $amount_in_cents,
            description => $description
            }
        };
    my $xml =  XMLout($ref, KeyAttr => $charge_or_credit, AttrIndent => 1, KeepRoot => 1, NoAttr => 1, XMLDecl => "<?xml version='1.0' standalone='yes' encoding='UTF-8'?>");
$req->add_content_utf8($xml);
#    $req->content(encode('UTF-8',$xml));
    #print $ua->request($req)->as_string;
    my $res = $ua->request($req);
    if ($res->is_success) {
#        print STDERR Dumper($res);
        my $xs = XMLin($res->decoded_content, ForceArray => 0, KeyAttr => $charge_or_credit, NoAttr => 1);
        my $id = $dbrh->quote($xs->{id});
        my $xml_response = $res->decoded_content;
        print "$xml_response\n";
        $xml_response =~ s/,/%2C/g; # uri_escape() without the collateral damage, reverses with uri_unescape
        my $md = $dbrh->quote(",$xs->{id}=$xml_response");
        my $rows;
        BRDB::db_exec2($dbrh, "UPDATE callees SET meta_data=CONCAT(meta_data,$md),external_id=$id,updated_at=NOW() WHERE id=$r->{id}", \$rows) or die;
        return $xs;
        }
    else {
        print STDERR "recurly REST API Error: " . $res->status_line . ": (id=$r->{id}); Dumping...\n";
        print STDERR Dumper($res);
        return undef;
        }
}

# ---
sub charge_for_one_callee
{
    my $did_something = 0;

    # ---
    my $data;
    # -- need to keep this limited to 1 so updates to the plan_usage are accurate (re-read after each possible update)
    # -- though I guess we could keep them in a hash ......... { account_id => plan_usage } .. hhhhmmmmm
    # -- downside is 1 bad record that can't be pushed out will stall the whole backlog ...
    BRDB::db_select2("SELECT c.id,c.participant,c.started,TIME_TO_SEC(TIMEDIFF(c.ended,c.started)) AS seconds,c.meta_data,c.accounting_code,c.accounting_desc,c.number,a.plan_code,a.plan_usage,a.plan_last_invoice,a.external_code,c.account_id FROM callees c, accounts a WHERE c.account_id=a.id AND c.started IS NOT NULL AND c.ended IS NOT NULL AND c.external_id IS NULL AND a.external_code IS NOT NULL ORDER BY c.updated_at LIMIT 1",\$data,$dbrh);
    foreach $r(@{$data}) {
        print "[new charge] processing id = $r->{id}\n";
        my $rows;

        # ---
        my ($ignore,$amount_in_cents,$description,$overage_in_cents,$overage_desc,$plan_usage_out) = rate_calc($r);
        
        # ---
        if ($ignore) {
            BRDB::db_exec2($dbrh, "UPDATE callees SET external_id='**ignore**',updated_at=NOW() WHERE id=$r->{id}", \$rows) or die;
            print "** Ignored (rate_calc) directed an ignore\n";
            die if $rows != 1;
            $did_something = 1; # mark that we did something so we continue to iterate thru the rest ...
            next;
            }

        my $last_invoice_id = get_last_invoice($r->{external_code});
        if (not defined $last_invoice_id) {
            print STDERR "get_last_invoice() just failed for this record: \n" . Dumper($r);
            print "get_last_invoice() just failed for this record: \n" . Dumper($r);
            last;
            }
        if ($last_invoice_id ne $r->{plan_last_invoice}) {
            # set new last invoice id, clear plan usages
            my $pli = $dbrh->quote($last_invoice_id);
            BRDB::db_exec2($dbrh, "UPDATE accounts SET plan_last_invoice=$pli,plan_usage='' WHERE id=$r->{account_id}", \$rows) or die;
            die if $rows != 1;
            # start over
            return 1;   # 1==did_something
            }

        # ---
        my $result = charge_or_credit($r,$amount_in_cents, $description);
        if (not defined $result) {
            print STDERR "charge_or_credit() just failed for this record: \n" . Dumper($r);
            print "charge_or_credit() just failed for this record: \n" . Dumper($r);
            last;
            }
        if ($plan_usage_out ne $r->{plan_usage}) {
            # --- update it
            my $puo = $dbrh->quote($plan_usage_out);
            BRDB::db_exec2($dbrh, "UPDATE accounts SET plan_usage=$puo,updated_at=NOW() WHERE id=$r->{account_id}", \$rows) or die;
            die if $rows != 1;  # TODO?
            }
        if ((($overage_in_cents)+0)>0) {
            # --- charge it
            $result = charge_or_credit($r,$overage_in_cents, $overage_desc);
            if (not defined $result) {
                print STDERR "charge_or_credit(overage) just failed for this record: \n" . Dumper($r);
                print "charge_or_credit(overage) just failed for this record: \n" . Dumper($r);
                last;
                }
            }

        $did_something = 1;
        }

    return $did_something;
}

# ---
sub charge_for_callees
{
    # sub-loop to avoid re-loading plans from DB for every row
    my $did_something = 0;
    for(my $i=0; $i<500; $i++) {
        last if not charge_for_one_callee();
        $did_something = 1;
        }
    return $did_something;
}

# ---
sub change_plans
{
    my $did_something = 0;

    # ---
    my $data;
    BRDB::db_select2("SELECT a.id, a.external_code, a.change_to_plan_code FROM accounts a,users u WHERE a.owner_id=u.id AND a.change_to_plan_code IS NOT NULL",\$data,$dbrh);
    foreach $r(@{$data}) {
        print "[change plans] processing account_code = $r->{external_code}\n";
        my $vars = undef;
        my $plan_code = $r->{change_to_plan_code};
        $plan_code = undef if $plan_code eq 'unsubscribe';
        my $req = '';
        if (defined $plan_code) {
            $req = open_recurly_request("PUT", "accounts/$r->{external_code}/subscription", \$vars);
            }
        else {
            # --- specifying refund=partial causes partial refund
            $req = open_recurly_request("DELETE", "accounts/$r->{external_code}/subscription?refund=partial", \$vars);
            }
        last if not defined $req;
        my $ua = LWP::UserAgent->new;
        my $account_code = $vars->{account_prefix} . $system_id . '-' . $r->{id};
        die "account_code mismatch [$r->{external_code}, $account_code]" if $r->{external_code} ne $account_code;
        if (defined $plan_code) {
            my $ref = {
                'subscription' => {
                    timeframe => 'now',
                    plan_code => $r->{change_to_plan_code},
                    quantity => 1,
                    }
                };
            # --- skip UTF-8 stuff 
            my $xml =  XMLout($ref, KeyAttr => 'subscription', AttrIndent => 1, KeepRoot => 1, NoAttr => 1, XMLDecl => "<?xml version='1.0' standalone='yes'?>");
            $req->content($xml);
            }
#print STDERR $req->as_string();
        my $res = $ua->request($req);
        print "dumping result ...\n" . Dumper($res);
#print STDERR "FINDX";
#print STDERR $xml;
#last;
        if ($res->code()==200) {
#            my $xs = XMLin($res->decoded_content, ForceArray => 0, KeyAttr => 'account', NoAttr => 1);
#            print "hosted_login_token => $xs->{hosted_login_token}\n";
            $plan_code = $dbrh->quote($plan_code);
#            my $hlt = $dbrh->quote($xs->{hosted_login_token});
            my $rows;
            # --- only clear change_to_plan_code --> push notification will actually push change thru ...
            #BRDB::db_exec2($dbrh, "UPDATE accounts SET plan_code=$plan_code,plan_usage=NULL,plan_last_invoice=NULL,change_to_plan_code=NULL,changing_flag=NULL,updated_at=NOW() WHERE id=$r->{id}", \$rows) or die;
            BRDB::db_exec2($dbrh, "UPDATE accounts SET change_to_plan_code=NULL,updated_at=NOW() WHERE id=$r->{id}", \$rows) or die;
            print STDERR "change_plans(): failed to mark change_to_plan_code NULL" . Dumper($r) if $rows != 1;
            $did_something = 1;
            }
        elsif ($res->code()==404) {
            # --- already unsubscribed
            BRDB::db_exec2($dbrh, "UPDATE accounts SET change_to_plan_code=NULL,changing_flag=NULL,updated_at=NOW() WHERE id=$r->{id}", \$rows) or die;
            print STDERR "change_plans(): failed to mark change_to_plan_code NULL" . Dumper($r) if $rows != 1;
            print STDERR "change_plans(): 404 (already unsubscribed?) returned " . Dumper($r);
            $did_something = 1;
            }
        elsif ($res->code()==422) {
            }
        else {
            print STDERR "recurly REST API Error: " . $res->status_line . ": (id=$r->{id}); Dumping...\n";
            print STDERR Dumper($res);
            }
        }

    return $did_something;
}

# ---
db_remote_connect() or die;
db_local_connect() or die;

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++)
{
    # --- clear cached plan data
    %cached_plans = ();

    my $did_something = 0;

    # ---
    $did_something = 1 if do_new_accounts();

    # ---
    $did_something = 1 if charge_for_callees();

    # ---
    $did_something = 1 if change_plans();

    # ---
    sleep $ENV{BR_SLEEP_SHORT} if not $did_something;
}

# ---
db_disconnect($dbh);
db_disconnect($dbrh);

exit 0;

