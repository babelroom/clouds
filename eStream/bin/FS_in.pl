#!/usr/bin/perl -w

# ======================================================================================================
# --- globals (customize)
$FSHost = '127.0.0.1';
$FSPort = '8021';
$resthost = '127.0.0.1:8888';
#$remote_host = "kowloon.sfo"; -- not currently used
# ======================================================================================================

use REST::Client;       # TODO: for groups only
use IO::Socket::INET;
use EStream;

$cid = $ARGV[0];

# ---
$SIG{PIPE} = "IGNORE";
#$starttime = `date`;
#$timestamp = time();
#$recording_file = "/br_media/conf_recordings/$cid\-$timestamp.wav";

# --- setup REST TODO: for groups only
my $client = REST::Client->new();
$client->setHost("http://$resthost");

# --- Create socket to FS
$MySocket=0;
sub check_connection
{
    # --- TODO
    # --- this is actually not needed as this script is started, per conference ...
    # --- ooops, and we have the whole curl dedacle again ....
    return if $MySocket;
    for(;;) {
        $MySocket=new IO::Socket::INET->new(PeerPort=>$FSPort,Proto=>'tcp',PeerAddr=>$FSHost);
        last if $MySocket;
        print STDERR "Could not open connection to FS event socket at ${FSHost}:${FSPort}: $!\n";
        sleep 5;
        }
}

check_connection();

# --- authenticate
$MySocket->send("auth jjj\r\n\r\n");

# --- record -- no, do auto record via conference auto config for the present
#$MySocket->send("api conference $cid record $recording_file\r\n\r\n");

# ---
sub send_cmd
{
    my $cmd = shift;
#print STDERR "sending[$cmd]\n";
    for(;;) {
        check_connection();
#print STDERR "sending cmd [$cmd]\n";
        $MySocket->send("$cmd\r\n\r\n") && last;
        print STDERR "cmd[$cmd] failed, resetting connection\n";
#print STDERR "1...\n";
        $MySocket = undef;
#print STDERR "2...\n";
        }
}

# --- this is depreciated and no longer used -- delete me
sub signal_move_to_group
{
    my ($cid, $me, $group) = @_;
#print STDERR "signal_move_to_group: ($cid) $me --> $group\n";
    $client->PUT("/conference/$cid", "Kmember-$me-group: $group");
    # TODO: error?
}

# --- this is depreciated and no longer used -- delete me
sub isolate_2_people
{
    my ($cid, $me, $peer) = @_;
#print STDERR "isolate_2_people: ($cid) $me <--> $peer\n";
    send_cmd("api conference $cid relate $me $peer nohear");
    send_cmd("api conference $cid relate $peer $me nohear");
    # TODO: error?
}

# --- this is depreciated and no longer used -- delete me
sub connect_2_people
{
    my ($cid, $me, $peer) = @_;
#print STDERR "connect_2_people: ($cid) $me >--< $peer\n";
    send_cmd("api conference $cid relate $me $peer clear");
    send_cmd("api conference $cid relate $peer $me clear");
    # TODO: error?
}

# ---
sub msg
{
    my $len = shift;
    my $data = shift;
#print STDERR "FS_in: msg=$data\n";
    if ($data=~/^F(.*)$/) {
        my $cmd = $1;
        send_cmd("$cmd");
        }
    elsif ($data=~/^M([^\s]+)\s+(.*)$/) {
        my $ids = $1;
        my $cmd = $2;
        my $level = ' ';
        $level .= $2 if $cmd =~ s/([^\s]+\s+)([-0-9]+)\s*$/$1/;
        foreach my $id (split(/,/,$ids)) {
            send_cmd("$cmd $id$level");
            }
        }
#    elsif ($data=~/^L([^\s]+)\s+(.*)\s([0-9-]+)\s*$/) {
#        my ($ids, $cmd, $level) = ($1,$2,$3);
#        foreach my $id (split(/,/,$ids)) {
#            send_cmd("$cmd $id $level");
#            }
#        }
    #  =             =
    # - - R o o m s - -
    #  =             =
#    elsif ($data=~/^B([^\s]+)\s+([^\s]+)\s+(\d+)\s*$/) {    # broadcast
#        my ($cid, $ids, $id) = ($1,$2, $3);
##print STDERR "broadcast: conference=>$cid        ids=>$ids     id=>$id\n";
#        foreach my $peer (split(/,/,$ids)) {
#            next if ($peer eq $id);
#            send_cmd("api conference $cid relate $peer $id clear");
#            signal_move_to_group($cid, $id, 'B');
#            }
#        }
    elsif ($data=~/^depreciated_D([^\s]+)\s+([^\s]+)\s*$/) {    # dissolve all rooms
        my ($cid, $ids) = ($1,$2);
#print STDERR "dissolve: conference=>$cid        ids=>$ids\n";
        my @list = split(/,/,$ids);
        my $len = ($#list+1);
#print STDERR "len: $len\n";
        for(my $i=0; $i<$len; $i++) {
            my $id = $list[$i];
#print STDERR "id: $id\n";
            signal_move_to_group($cid, $id, 0);
            for(my $j=$i; $j<$len; $j++) {
                my $jd = $list[$j];
#print STDERR "jd: $jd\n";
                next if ($id eq $jd);
                connect_2_people($cid,$id,$jd);
                }
            }
        }
    elsif ($data=~/^H([^:]+)::::(.*)$/) {    # hangup
        my ($token) = ($1);
#print STDERR "0: $token\n";
        if (length($token)>10) {    # a little paranoia
            my $cmd = "bgapi hupall normal_clearing BR-outbound-token $token";
            send_cmd($cmd);
#print STDERR "1: $cmd\n";
            }
        }
    elsif ($data=~/^O(\d{6}):(\+?\d+):([^:]+):(.*)$/) {    # originate (dialout)
        my ($pin, $number, $token, $cid_name) = ($1,$2,$3,$4);
        $cid_name =~ s/'//;
        my $cmd = "bgapi originate {BR-pin=$pin,BR-outbound-token=$token}sofia/gateway/flowroute/$number dialout XML public '$cid_name' 14154498899";
        send_cmd($cmd);
        }
#    elsif ($data=~/^R([^:]+):(.*)$/) {
#XXXXX
#        my $cmd = "bgapi originate {BR-pin=$pin,BR-outbound-token=$token}sofia/gateway/flowroute/$number dialout XML public '$cid_name' 15109910999";
#        send_cmd($cmd);
#        }
    elsif ($data=~/^depreciated_R([^\s]+)\s+([^\s][0-9, B]+[^\s])\s+:\s*([^\s][0-9, B]+[^\s])\s*$/) {
        my ($cid, $current, $new) = ($1,$2,$3);
#print STDERR "moveToRoom: conference=>$cid        current=>$current        new=>$new\n";
        my %old_map = ();
        foreach my $pair(split(/\s+/, $current)) {
            if (not $pair =~ /^(\d+),([\dB]+)$/) {
                print STDERR "bad current to room pair [$pair]\n";
                next;
                }
            #my $key = ($1+0);
            #$old_map{$key} = ($2+0);
            my $key = $1;
            $old_map{$key} = $2;
#print STDERR "old_map{$key}=$old_map{$key}\n";
            }
        my %new_map = %old_map;
        my $tomove = '';
        foreach my $pair(split(/\s+/, $new)) {
            if (not $pair =~ /^(\d+),([\dB]+)$/) {
                print STDERR "bad new room pair [$pair]\n";
                next;
                }
            #my $key = ($1+0);
            #$new_map{$key} = ($2+0);
            my $key = $1;
            $new_map{$key} = $2;
            $tomove .= "$key,";
#print STDERR "new_map{$key}=$new_map{$key}\n";
            }
        foreach my $me (split(/,/, $tomove)) {
            my $room = $new_map{$me};
            # $me is moving to room $room
#print STDERR "1 me=$me, room=$room\n";
            next if $old_map{$me} eq $room;      # already in that room, no change
            signal_move_to_group($cid, $me, $room);
            if ($room eq 'B') {
#        foreach my $peer (split(/,/,$ids)) {
                signal_move_to_group($cid, $me, 'B');
                foreach my $peer (keys %old_map) {
                    next if ($peer eq $me);
#print STDERR "broadcast: me=$me, peer=$peer\n";
                    send_cmd("api conference $cid relate $peer $me clear");
                    }
#            next if ($peer eq $id);
#            send_cmd("api conference $cid relate $peer $id clear");
#            signal_move_to_group($cid, $id, 'B');
#            }
                }
            else {
                my $my_old_room = $old_map{$me};
                foreach my $peer(keys %old_map) {
#print STDERR "2 me=$me, peer=$peer\n";
                    next if $peer==$me;
                    my $was_in_same_room = (($old_map{$peer} eq $my_old_room) or ($my_old_room eq 'B'));
                    my $now_in_different_room = ($new_map{$peer} ne $room);
                    isolate_2_people($cid, $me, $peer) if $was_in_same_room and $now_in_different_room;
                    connect_2_people($cid, $me, $peer) if not $was_in_same_room and not $now_in_different_room;
                    }
                }
            }
        }
}

# -- make sure queue exists
$client->POST("/fs/$cid");
# TODO: error?

# --- commented out for stream module
## -- now listen
#open F, "/usr/bin/curl -N -s $resthost/fs/$cid?fmt=1 |";
#$old_data = '';
#while (length($old_data) || ($n = sysread F, $data, 8192) != 0) {
#    $whole_data = ($old_data . $data);
##print STDERR "wd=[$whole_data]\n";
#    if ($whole_data =~ /^\s*(\d+)(.*)$/) {
#        $len = $1;
#        $data = $2;
#        if (length($data)>$len) {
#            $old_data = substr($data, $len);
#            $data = substr($data, 0, $len);
#            }
#        else {
#            $old_data = '';
#            }
#        msg($len, $data);
#        $data = undef;
#        }
#    else {
#        print STDERR "bad read -- $n bytes read [$whole_data]\n";
#        }
##    print "$n bytes read\n";
#    } 
##foreach(<F>){
##    print "A[$_]\n";
##    }
#
### --- not currently used ... re-add $starttime and $recording_file if used
## create record for call
## ---
###`/usr/bin/scp -P 54320 $recording_file $remote_host:$recording_file`;
##$endtime = `date`;
##exec("/usr/bin/curl -X POST -d 'call[startTime]=$starttime&call[endTime]=$endtime&call[conference_id]=$cid&call[recording_file]=$recording_file' $url");
# --- END of commenting out for estream module

# ---
my $url = "http://$resthost/fs/$cid";
$esh = estream_open("$url") or die "Could not connect to $url";

# ---
my $data;
my $len;
while(($len=estream_read($esh,\$data))) {
    msg($len, $data);
}

# ---
#close(F);
estream_close($esh) if $esh;
db_disconnect($dbh) if defined $dbh;

# ---
exit 0;

