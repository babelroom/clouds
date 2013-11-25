#!/usr/bin/perl

# ---
#BR_description: Push freeswitch records out to assigned server
#BR_startup: running=always
#BR__END: 
# ---

# ---
$|++;
use BRDB;
use BRUDP;
use REST::Client;
use Data::Dumper;

# ---
sub get_ready_conferences
{
    $conferences = [];
    db_select("SELECT id,name,fs_server,conference_key FROM conferences WHERE state='ready_to_deploy'",'conferences',$dbh) or die;
    return $#{$conferences}+1;
}

# ---
sub get_assigned_people
{
    $people = [];
    db_select("SELECT id,name,last_name,dialout,email,configuration,pin,fs_server,origin_id,conference_id FROM people WHERE is_deleted IS NULL AND pin IS NOT NULL AND fs_server IS NOT NULL AND deployed_at IS NULL",'people',$dbh) or die;
    return $#{$people}+1;
}

# ---
sub deploy_conferences
{
    # ---
    foreach my $r(@{$conferences}) {
        die if not defined $r->{fs_server};
        my $client = REST::Client->new();
        next if not $r->{fs_server} =~ /ipv4=([^,]+)/;
        my $host = $1;
        $host .= ":$1" if $r->{fs_server} =~ /es_port=(\d+)/;
        my $url = "http://$host/rest/conference/$r->{id}";
        my $recording_root = sprintf("%s-%012d", $r->{conference_key}, $r->{id});
        my $data =  <<__EOT__
conference-id: $r->{id}
conference-name: $r->{name}
conference-key: $r->{conference_key}
conference-recording-root: $recording_root
__EOT__
;
        $client->POST($url, $data) or die "failed to PUT to [$url]\n";
        die "bad response from [$url]\n" if $client->responseCode() ne '200';
        db_exec($dbh,"UPDATE conferences SET state='deployed', updated_at=NOW() WHERE id=$r->{id}",_rows);
        if ($_rows>0) {
            print "Conference deployed on $url:\n";
            print "================================================================================\n";
            print "$data";
            print "================================================================================\n";
            }
        }
}

# ---
sub notify
{
    my ($host, $data, $cid) = @_;
    my $url = "http://$host/conference/$cid";
    my $client = REST::Client->new();
    die if not defined $client;
    $client->PUT($url,$data);
    my $rc = $client->responseCode();
    print "Notification of person deployed on $url, rc=$rc\n";
    return ($rc==200);
}

# ---
sub deploy_people
{
    # ---
    foreach my $r(@{$people}) {
        my $client = REST::Client->new();
        next if not $r->{fs_server} =~ /ipv4=([^,]+)/;
        my $host = $1;
        $host .= ":$1" if $r->{fs_server} =~ /es_port=(\d+)/;
        if (!length($host) || !length($r->{pin})) {
            print STDERR "bad data", Dumper($r);
            next;
            }
        my $url = "http://$host/rest/pin/$r->{pin}";
        my $data =  <<__EOT__
cid: $r->{conference_id}
pin: $r->{pin}
user-id: $r->{origin_id}
person-id: $r->{id}
person-name: $r->{name} $r->{last_name}
person-dialout: $r->{dialout}
person-email: $r->{email}
person-role: $r->{configuration}
__EOT__
;
        $client->POST($url, $data) or die "failed to POST to [$url]\n";
        die "bad response from [$url]\n" if $client->responseCode() ne '200';
        db_exec($dbh,"UPDATE people SET deployed_at=NOW(), updated_at=NOW() WHERE id=$r->{id}",_rows);
        if ($_rows>0) {
            print "Person deployed on $url:\n";
            print "================================================================================\n";
            print "$data";
            print "================================================================================\n";
            notify($host, "Kpin-$r->{pin}: $r->{origin_id}", $r->{conference_id});
            }
        }
}

# ---
$dbh = db_quick_connect();
$udp = BRUDP->new(Port=>$ENV{BR_UDPPORT}) or die;

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
{
    $did_something = 0;

    # ---
    if (get_ready_conferences()) {
        if (deploy_conferences()) {
            $did_something = 1;
            }
        }

    # ---
    if (get_assigned_people()) {
        if (deploy_people()) {
            $did_something = 1;
            }
        }

    # ---
#    sleep $ENV{BR_SLEEP_SHORT} if not $did_something;
    ($udp->recv('no_conference:ready_to_deploy', $ENV{BR_SLEEP_SHORT}) or die) if not $did_something; 
}

# ---
db_disconnect($dbh);

exit 0;

