#!/usr/bin/perl

# ======================================================================================================
# --- globals (customize)
$FSHost = '127.0.0.1';
$FSPort = '8021';
$resthost = '127.0.0.1:8888';
# ======================================================================================================

# ---
# FreeSWITCH event forwarder
# ---
use REST::Client;
use IO::Socket::INET;
use URI::Escape;

# ---
use POSIX ":sys_wait_h";
sub REAPER {
    my $child;
    while (($child=waitpid(-1,WNOHANG))!=-1) {
#        $child_status{$child} = $?;
# this doesn't work so well ...
#        local $cname = $known_conferences_pids{$child};
#        if (defined $cname) {
#            $known_conferences{$cname} = undef;
#            $known_conferences_pids{$child} = undef;
#            }
        last;
    }
    $SIG{CHLD} = \&REAPER;
}
$SIG{CHLD} = \&REAPER;

# --- setup REST
my $client = REST::Client->new();
$client->setHost("http://$resthost");

# ---
sub log_out
{
    my $msg = shift;
    print scalar(localtime).": $msg\n";
}
sub log_err
{
    my $msg = shift;
    print STDERR scalar(localtime).": $msg\n";
    log_out($msg);
}
sub fmt_time_utc
{
    my $t = shift;
    $t = ($t+0) / 1000000;
    $t = int($t + 0.5);
#    @t = gmtime($t); -- artefact ??
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=gmtime($t);
    $t = sprintf "%4d-%02d-%02d %02d:%02d:%02d",
        $year+1900,$mon+1,$mday,$hour,$min,$sec;

    return $t;
}

# ---
%known_conferences = ();
%known_conferences_pids = ();
sub maybe_conference_up
{
    my $cname = shift;
    my $edl = shift;
    my $uuid = shift;
    return if defined $known_conferences{$cname};
    $client->POST("/conference/_status","Conference-$cname-actual_start: $edl");
    local $pid = fork();
    if ($pid==-1) {
        print STDERR "fork() failed: $!\n";
        }
    elsif ($pid) {
        $known_conferences{$cname} = $pid;
        $known_conferences_pids{$pid} = $cname;
        $client->PUT("/conference/$cname", "R");                                        # clear/reset dashboard
        # these 2 are moved from client br_commands in response to 'R', better for compression to enter as K values here ...
        $client->PUT("/conference/$cname", "Klock");
        $client->PUT("/conference/$cname", "Krecording");
# these next 3 are being depreciated as they are not currently used and they add data to the queue that is not (easily) purgible
#        $client->PUT("/conference/$cname", "S".scalar(localtime()));                    # TODO: this is just playing ...
#        $client->PUT("/conference/$cname", "T".$$uuid{'conference-name'});              # shortly, pre-populate participants
#        $client->PUT("/conference/$cname", "LThe conference has started. Monitoring attached \@$pid");
        }
    else {
        exec("./FS_in.pl $cname");
        die "Why am I still here?: $!\n";
        }
}

# ---
sub conference_down
{
    my $cname = shift;
    my $edl = shift;

    # when we delete the queue estream will kill the socket and FS_in.pl 
    # for this conference will terminate
    $client->DELETE("/fs/$cname");
    $client->PUT("/conference/_status","Conference-$cname-actual_end: $edl");
#    local $pid = $known_conferences{$cname};
#    return if not defined $pid;
#    kill(15,$pid) || print STDERR "kill for pid=$pid failed:$!\n";
    $known_conferences{$cname} = undef; # tmp. workaround, above code in signal handler doesn't work so well
}

# ---
sub FS_event()
{
    my $ev = $H{'Event-Name'};
    return CUSTOM_event() if $ev eq 'CUSTOM';

    # ---
    my $uuid = $H{'Caller-Unique-ID'};
    if ($ev eq 'CHANNEL_DESTROY') {
        # --- THIS is meant to notify when an outbound call ends, so the
        # "dialing" display can be cleared
        # problem is it doesn't work so well if the conferences is not already up and running ...
        # i.e. this process ... guess leave it in for now ...
        my $ot = $$uuid{'outbound-token'};
# clear unnecessary clutter 
#        if (length($ot)>0) {
#            $client->PUT("/conference/$cname", "Doutbound-$ot");
#            }
        # --- end of THIS
        %$uuid = undef;
        return 1;
        }
    elsif ($ev eq 'DTMF') {
        my $cname = $$uuid{'cid'};
        my $mid = $$uuid{'Member-ID'};
        my $digit = $H{'DTMF-Digit'};
#print STDERR "DTMF: uuid => $uuid, cname => $cname, mid => $mid, digit => $digit\n";
        $client->PUT("/conference/$cname", "Kmember-$mid-poll:" . $digit);
        return 1;
        }

    return if $ev ne 'CHANNEL_EXECUTE_COMPLETE' or $H{'Application'} ne 'lua';
    # a BR lua script has completed, read in what it just read ...
    foreach my $key(keys %H) {
        next if $key !~ /^variable_BR-(.+)$/;
        ${$uuid}{$1} = $H{$key};
        }
}

# ---
%H = ();
sub CUSTOM_event()
{
#    my $console_data = '';
#    foreach my $key(keys %H) {
#        $console_data .= "        \[$key:$H{$key}\]\n";
#        }
#    $client->PUT('/conference/0', "L$console_data");
#$| = 1; print STDOUT "$console_data\n";
#print STDOUT "$console_data\n";


    $ev = $H{'Event-Name'};
    $evsc = $H{'Event-Subclass'};
#    $edl = $H{'Event-Date-Local'};
    $edl = fmt_time_utc($H{'Event-Date-Timestamp'});
    $mid = $H{'Member-ID'};
    $cname = $H{'Conference-Name'};
#print "CNAME=$cname\n";
    $name = $H{'Caller-Caller-ID-Name'};
    $ANI = $H{'Caller-ANI'};
#    $uuid = $H{'variable_uuid'};
    $uuid = $H{'Caller-Unique-ID'};
    if ($name ne $ANI) {
        $ANI .= " ($name) ";
        }
    $a = $H{'Action'};
#    if (length $n) {
#        $client->PUT("/conference/$cname", "L    [$H{'Event-Name'} $n]");
#        }

    return if $ev ne 'CUSTOM' or length($cname)==0 or $evsc ne 'conference::maintenance';

#    $std = "attr = {\"value\": \"$mid\"";
#print "mid=$mid, cname=$cname\n";

    if (0) { }
    elsif ($a eq 'add-member') {
        maybe_conference_up($cname,$edl,$uuid);
#        $client->PUT("/conference/$cname", "PA$std, \"text\":\"$ANI\", \"color\":\"blue\", \"onclick\":\"mute $mid\"};");
#        $client->PUT("/conference/$cname", "Kmember-$mid:");
        $client->PUT("/conference/$cname", "Kmember-$mid:" . $$uuid{'outbound-token'});
        $client->PUT("/conference/$cname", "Kmember-$mid-callerid: $ANI");
        $client->PUT("/conference/$cname", "Kmember-$mid-user_id:" . $$uuid{'user-id'});
        $client->PUT("/conference/$cname", "Kmember-$mid-name:" . $$uuid{'person-name'});
        $client->PUT("/conference/$cname", "Kmember-$mid-email:" . $$uuid{'person-email'});
        $client->PUT("/conference/$cname", "Kmember-$mid-dialout:" . $$uuid{'person-dialout'});
        $client->PUT("/conference/$cname", "Kmember-$mid-role:" . $$uuid{'person-role'});

        # set conference member-ID
        $$uuid{'Member-ID'} = $mid;

        # --- review these
#        $client->PUT("/conference/$cname", "LCaller $ANI has joined the conference");
#            . ',cdir=' . uri_escape(lc(substr($H{'Call-Direction'},0,1))) -- not needed, dialin=='dialout' for outbound
        my $md = ''
            . ',pid=' . uri_escape($$uuid{'person-id'})
            . ',mid=' . uri_escape($mid)
            . ',cid=' . uri_escape($$uuid{'conference-id'})
            . ',callid=' . uri_escape($H{'Caller-Caller-ID-Name'})
            . ',codec=' . uri_escape(   $H{'Channel-Read-Codec-Name'}.':'.$H{'Channel-Read-Codec-Rate'}.':'.$H{'Channel-Read-Codec-Bit-Rate'}.
                                    ':'.$H{'Channel-Write-Codec-Name'}.':'.$H{'Channel-Write-Codec-Rate'}.':'.$H{'Channel-Write-Codec-Bit-Rate'})
            . ',ani=' . uri_escape($$uuid{'ani'})
            . ',dialin=' . uri_escape($$uuid{'dialin'})
            . ',started=' . uri_escape($edl)
            . ',start_ts=' . uri_escape($H{'Event-Date-Timestamp'});
        $client->PUT("/conference/_status","Channel-${uuid}: $md");

        # --- done with $$uuid, drop it
# undef this hash here when we develop an FS module
#        %$uuid = undef; -- right now got to keep this around for DTMF (polling) process
        }
    elsif ($a eq 'del-member') {
        $client->PUT("/conference/$cname", "Kmember-$mid");
#print STDERR "D=$n\n";
#        $client->PUT("/conference/$cname", "LCaller $ANI has left the conference");
        if ($H{'Conference-Size'} eq '0') {
#            $client->PUT("/conference/$cname", "LThe conference has ended");
#            $client->PUT("/conference/$cname", "E".scalar(localtime()));            # TODO: this is just playing
            conference_down($cname,$edl);
            }
        my $md = ''
            . ',ended=' . uri_escape($edl)
            . ',end_ts=' . uri_escape($H{'Event-Date-Timestamp'});
        $client->PUT("/conference/_status","Channel-${uuid}: $md");
#        $client->PUT("/conference/_status","Channel-${uuid}_ended: $edl");
        }
    elsif ($a eq 'start-talking') {
        $client->PUT("/conference/$cname", "Ktalking-$mid:");
        }
    elsif ($a eq 'stop-talking') {
        $client->PUT("/conference/$cname", "Ktalking-$mid");
        }
    elsif ($a eq 'lock') {
        $client->PUT("/conference/$cname", "Klock:");
        }
    elsif ($a eq 'unlock') {
        $client->PUT("/conference/$cname", "Klock");
        }
    elsif ($a eq 'mute-member') {
        $client->PUT("/conference/$cname", "Kmember-$mid-mute:");
        }
    elsif ($a eq 'unmute-member') {
        $client->PUT("/conference/$cname", "Kmember-$mid-mute");
        }
    elsif ($a eq 'pa-member') {
        $client->PUT("/conference/$cname", "Kmember-$mid-pa:");
        }
    elsif ($a eq 'unpa-member') {
        $client->PUT("/conference/$cname", "Kmember-$mid-pa");
        }
    elsif ($a eq 'deaf-member') {
        $client->PUT("/conference/$cname", "Kmember-$mid-deaf:");
        }
    elsif ($a eq 'undeaf-member') {
        $client->PUT("/conference/$cname", "Kmember-$mid-deaf");
        }
    elsif ($a eq 'group') {
        my ($new_group,$mids) = ($H{'New-Group'}, $H{'Member-List'});
        foreach my $_mid (split /,/, $mids) {
            $client->PUT("/conference/$cname", "Kmember-$_mid-group: $new_group");
            }
        }
    elsif ($a eq 'start-recording') {
        my $path = $H{'Path'};
        $client->PUT("/conference/$cname", "Krecording: $path");
        }
    elsif ($a eq 'stop-recording') {
        my $path = uri_escape($H{'Path'});
        my $ts = uri_escape($H{'Event-Date-Timestamp'});
        $client->PUT("/conference/_status","Recording-$cname-$path: $ts");
        $client->PUT("/conference/$cname", "Krecording");
        }
}

# ---
sub do_listen_loop
{
    my $msg;
    while($msg=<$MySocket>) {
        chomp $msg;
        if (not length $msg) {
#print STDOUT "\n";
            if (defined $H{'Event-Name'}) {
                FS_event();
#print STDOUT "===========================================================================================\n";
                }
            %H = ();
#$! = 1; print STDOUT "\n";
            }
        else {
            if (not $msg=~/^([^:]*):\s(.*)$/) {
                print STDERR "message response (or bad key-value pair): [$msg]\n";    # this is also where msg responses come out, i.e. "OK mute 6"
                }
            else {
                my $key = $1;
                my $value = $2;
                $value =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;  # urldecode
                $H{$key} = $value;
#print STDOUT "$key:$value\n";
                }
            }
        }
}

#  ---
while(1)
{
    # ---
    log_out("Connecting to FreeSWITCH event socket at [${FSHost}:${FSPort}] ...");
    if (($MySocket=new IO::Socket::INET->new(PeerPort=>$FSPort,Proto=>'tcp',PeerAddr=>$FSHost))) {

        log_out "Connecting to FreeSWITCH event socket, sending authentication and event commands";
        if ($MySocket->send("auth jjj\r\n\r\n") and $MySocket->send("event plain ALL\r\n\r\n")) {
            log_out "Connected to FreeSWITCH event socket, entering listen loop";
            do_listen_loop();
            log_err "dropped out of listen loop";
            }
        else {
            # -- fyi, don't think this would raise any error, (possible) TODO: check response??
            log_err "Failed sending authentication and event commands";
            }
        }
    else {
        log_err "Failed to connect to FreeSWITCH event socket at ${FSHost}:${FSPort}";
        }

    # ---
    sleep 2;    # avoid busy loop
}

# ---
exit 0;

