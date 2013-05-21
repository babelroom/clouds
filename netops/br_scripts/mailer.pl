#!/usr/bin/perl

#
# bug: 
#[cs@no001 log]$ cat 27459.* 
#Email::Send::Gmail: no valid recipients at /usr/local/share/perl5/Email/Send.pm line 252
# at /usr/local/share/perl5/Email/Send.pm line 252
#Tue Jul 12 20:28:22 2011 SQL{LOCAL}: [SELECT id,template,kv_pairs,updated_at,system_id FROM emails WHERE content IS NULL]
#Tue Jul 12 20:28:22 2011 SQL{LOCAL}: [0 rows]
#Tue Jul 12 20:28:22 2011 SQL{LOCAL}: [SELECT id,content,progress,updated_at FROM emails WHERE content IS NOT NULL AND (final_status IS NULL OR final_status='')]
#Tue Jul 12 20:28:22 2011 SQL{LOCAL}: [32 rows]
#Tue Jul 12 20:28:22 2011 SQL{LOCAL}: [SELECT id,name,access FROM systems WHERE system_type = 'outbound_email' ORDER BY id]
#Tue Jul 12 20:28:22 2011 SQL{LOCAL}: [3 rows]


# ---
#BR_description: Expand email from templates and send 'em
#BR_startup: running=always
#BR__END: 
# ---

# ---
$|++;
use BRDB;
use Text::Template;
use Email::Send;
use Email::Send::Gmail;

# ---
$mail_template_dir = $ENV{BR_MAIL_TEMPLATE_DIR};
$mail_gw = undef;

# ---
sub find_mail_template_source
{
    my $template_name = shift;
    my $system_id = shift;
    my $ouid = shift;
    my @dirs = ("$system_id/$ouid/", "$system_id/", ''); 
    my @suffixes = ('.html', '.txt', '');
    foreach my $d(@dirs) {
        foreach my $s(@suffixes) {
            my $test = "$mail_template_dir/$d$template_name$s";
            print "mailer: looking for template in [$test]\n";
            return $test if -f $test and -r $test;
            }
        }
    die "No source found for template '$template_name' on system $system_id\n";
    return undef;
}

# ---
sub expand_mail_content
{
    my $r = shift;  # a mail record
    my %vars = ();
    foreach(split(/\n/, $r->{kv_pairs})) {
        $vars{$1}=$2 if /^([^=]+)=(.*)$/;
        $vars{$1} =~ s/\\n/\n/g;
        }
    my $source = find_mail_template_source($r->{template},$r->{system_id},$vars{ouid}) or return 0;
    my $template = Text::Template->new(SOURCE=>$source)
        or die "Failed to construct template: $Text::Template::ERROR";
    my $c = $dbh->quote($template->fill_in(HASH => \%vars));
    $template = undef;
    db_exec($dbh,"UPDATE emails SET content=$c,updated_at=NOW() WHERE id=$r->{id} AND content IS NULL AND updated_at='$r->{updated_at}'","_rows") or die;
    return $_rows>0;
}

# ---
sub send_mail
{
    my $r = shift;  # a mail record
    my $content = $r->{content};

    # --- this to be reviewed
    my ($mailer_name,$one,$two) = split /\//, $mail_gw;
    my $mailer = Email::Send->new({mailer => $mailer_name}) or die $mailer;
    if ($mailer_name eq 'Gmail') {
        $mailer->mailer_args([username => $one, password => $two]) or die;
        }
    else {
        $mailer->mailer_args([Host=>$one]) or die;
        }
#my $email = Email::Simple->create(
#        header => [
#            From        => 'root@evil.bad',
#            To          => 'to_to@yahoo.com',
#            ],
#            body        => $content,
#    );
#$result = $mailer->send($email) or die $result;
    my $result = undef;
    # --- try..catch
    my $errmsg = '';
    eval {
        $result = $mailer->send($content);
        1; }    # need the "1;" here for older perls <5.14 ... -- which we ARE!!
    or do {
        my $e = $@;
        my $msg = "Exception caught sending mail: $e\n";
        print STDERR $msg;
        print $msg;
        $errmsg = $msg;
        };
    if ($result) {
        db_exec($dbh,"UPDATE emails SET final_status='sent (via $mailer_name)',updated_at=NOW() WHERE id=$r->{id}","_rows");
        }
    else {
        $errmsg = $dbh->quote($errmsg);
        db_exec($dbh,"UPDATE emails SET progress=$errmsg,final_status='errored',updated_at=NOW() WHERE id=$r->{id}","_rows");
        }
    $mailer = undef;
    return 1;
}

# ---
sub find_mail_server {
    $_systems = [];
    db_select("SELECT id,name,access FROM systems WHERE system_type = 'outbound_email' ORDER BY id",'_systems',$dbh) or return 0;

    # ---
    foreach my $r(@{$_systems}) {
        my %vars = ();
        foreach(split ',', $r->{access}){
#print STDERR "var==$_\n";
            $vars{$1} = '' if /^([^=]*)$/;
            $vars{$1} = $2 if /^([^=]*)=(.*)$/;
            }
        next if defined $vars{disabled};
        $mail_gw = $vars{mail_gw} if defined $vars{mail_gw};
        last if defined $mail_gw;
        }
    return defined($mail_gw) ? 1 : 0;
}

# ---
$dbh = db_quick_connect();

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
{
    # ---
    my $did_something = 0;
   
    # ---
    db_select("SELECT id,template,kv_pairs,updated_at,system_id FROM emails WHERE content IS NULL",'_new',$dbh) or die;
    foreach my $r(@{$_new}) {
        $did_something = 1 if expand_mail_content($r);
        }

    # ---
    db_select("SELECT id,content,progress,updated_at FROM emails WHERE content IS NOT NULL AND (final_status IS NULL OR final_status='')",'_new',$dbh) or die;
    my @results = @{$_new};
    if ($#results>-1 and not defined $mail_gw) {
        if (find_mail_server()) {
            print "Using mail gateway [$mail_gw]\n";
            }
        else {
            print STDERR "No mail gateway configured\n";
            sleep $ENV{BR_SLEEP_LONG};
            next;   # start over
            }
        }
    if (defined $mail_gw) {
        foreach my $r(@results) {
            $did_something = 1 if send_mail($r);
            }
        }
    $mail_gw = undef;

    # ---
    sleep $ENV{BR_SLEEP_SHORT} if not $did_something;
}

## ---
db_disconnect($dbh);

exit 0;

