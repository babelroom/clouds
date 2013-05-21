#!/usr/bin/perl

# don't set chmod +x permissions on this -- its for the cmd line only

$|++;
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple qw(:strict);
use Data::Dumper;
#use BRDB;
#use BRConfig;
#use BRRate;

## ---
#$rdsn=$dbruser=$dbrpass=$system_id=undef;
#foreach(split ',', $ENV{BR_PARAMETERS}){
#    next if not /^(.*)=(.*)$/;
#    $rdsn = $2 if $1 eq 'dsn';
#    $dbruser = $2 if $1 eq 'dbuser';
#    $dbrpass = $2 if $1 eq 'dbpass';
#    $system_id = $2 if $1 eq 'system_id';
#}
#$dsn = $ENV{BR_DSN};
#$dbuser = $ENV{BR_DBUSER};
#$dbpass = $ENV{BR_DBPASS};
#%cached_plans = ();
#
## ---
#sub db_local_connect { $dbh = db_connect($dsn, $dbuser, $dbpass,'LOCAL'); }
#sub db_remote_connect { $dbrh = db_connect($rdsn, $dbruser, $dbrpass,'REMOT'); }

# ---
sub open_recurly_request
{
    my $method = shift;
    my $uri = shift;
    my $data;
#    my $vars = BRConfig::get($dbh,undef,'recurly');
#    if (not defined $vars) {
#        print "No recurly configuration!\n";
#        print STDERR "No recurly configuration!\n";
#        return undef;
#        }
    my %_sandbox_vars = (
        url => 'https://api-sandbox.recurly.com/',
        auth_user => 'api-test@tld.com',
        auth_pass => 'c26f72ff9f00000db8142b5109e04150',
        );
    my %_production_vars = (
        url => 'https://api-production.recurly.com/',
        auth_user => 'api@tld.com',
        auth_pass => '20b18e5dfd00000fb3a81cdef8aae9e7',
        );
    my %vars = %_sandbox_vars;
    my $req = HTTP::Request->new($method => "$vars{url}$uri");
    $req->header('Accept' => 'application/xml');
    $req->header('Content-Type' => 'application/xml; charset=utf-8');
    $req->authorization_basic($vars{auth_user},$vars{auth_pass});
    return $req;
}

# ---
sub close_acct
{
    my $account_code = shift;
    my $req = open_recurly_request(DELETE,"accounts/$account_code");
    die if not defined $req;
    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);
    if ($res->is_success) {
        print "Acct [$account_code] closed\n";
        }
    else {
        print "Acct [$account_code] error\n";
        print STDERR "recurly REST API Error: " . $res->status_line . ": (id=$r->{id}); Dumping...\n";
        print STDERR Dumper($res);
        }
    return;
}

#close_acct('2');
for(my $i=1; $i<110; $i++) {
    close_acct('D2-'.$i);
#    close_acct('S1-'.$i);
#    close_acct('T'.$i);
#    close_acct(''.$i);
    }

exit 0;

