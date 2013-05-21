#!/usr/bin/perl

# ---
#BR_description: Undeploy a conference from a server
#BR_startup: running=always
#BR__END: 
# ---

# ---
$|++;
use BRDB;
use REST::Client;

# ---
sub get_a_conference
{
    my $result_ref = shift;
    $conferences = [];
    db_select("SELECT id,name,state,fs_server FROM conferences WHERE state='ended' OR state='undeploy' OR state='undeploy_then_delete' ORDER BY updated_at LIMIT 1",'_conf',$dbh) or die;
    return 0 if $#{$_conf}<0;
    die if $#{$_conf}>0;
    $$result_ref = ${$_conf}[0];
}

# ---
sub undeploy_the_people
{
    my $c = shift;
    my $cid = $c->{id};
    print STDERR "IMPLEMENT ME: undeploy people from conference $cid\n";
    return 1;

# ref:
# ---
#sub get_assigned_people
#{
#    $people = [];
#    db_select("SELECT id,name,last_name,dialout,email,configuration,pin,updated_at,fs_server,conference_id FROM people WHERE is_deleted IS NULL AND fs_server IS NOT NULL AND deployed_at IS NULL",'people',$dbh) or die;
#    return $#{$people}+1;
#}

}

# ---
sub undeploy_the_conference
{
    my $c = shift;
    my $cid = $c->{id};

    print STDERR "IMPLEMENT ME: undeploy conference $cid\n";

    my %next_states = (
        'ended' => 'closed',
        'undeploy_then_delete' => 'deleted',
        'undeploy' => 'undeployed'
        );
    my $next_state = $dbh->quote($next_states{$c->{state}});
    db_exec($dbh,"UPDATE conferences SET state=$next_state, updated_at=NOW() WHERE id=$cid",_rows) or die;
    return $#_rows+1;

# ref:
#        $host .= ":$1" if $r->{fs_server} =~ /es_port=(\d+)/;
#        my $url = "http://$host/rest/pin/$r->{pin}";
##
#    # ---
#    foreach my $r(@{$conferences}) {
#        die if not defined $r->{fs_server};
#        my $client = REST::Client->new();
#        next if not $r->{fs_server} =~ /ipv4=([^,]+)/;
#        my $host = $1;
#        $host .= ":$1" if $r->{fs_server} =~ /es_port=(\d+)/;
#        my $url = "http://$host/rest/conference/$r->{id}";
#        my $data =  <<__EOT__
#Id: $r->{id}
#Name: $r->{name}
#Updated-At: $r->{updated_at}
#conference-id: $r->{id}
#conference-name: $r->{name}
#__EOT__
#;
#        $client->POST($url, $data) or die "failed to POST to [$url]\n";
#        die "bad response from [$url]\n" if $client->responseCode() ne '200';
#        db_exec($dbh,"UPDATE conferences SET deployed_at=NOW(), state='deployed', updated_at=NOW() WHERE id=$r->{id}",_rows);
#        if ($_rows>0) {
#            print "Conference deployed on $url:\n";
#            print "================================================================================\n";
#            print "$data";
#            print "================================================================================\n";
#            }
#        }

}

# ---
$dbh = db_quick_connect();

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
{
    $did_something = 0;

    # ---
# this doesn't do anything right now and actually appears to conflict with "conference_close" and also
# stop proper re-scheduling of conferences. so disabled until the exact workflow is sorted out
# 
#    my $c = undef;
#    if (get_a_conference(\$c) and undeploy_the_people($c) and undeploy_the_conference($c)) {
#        $did_something = 1;
#        }

    # ---
    sleep $ENV{BR_SLEEP_SHORT} if not $did_something;
}

# ---
db_disconnect($dbh);

exit 0;

