#!/usr/bin/perl

use warnings;
use strict;

use Socket qw(:all);

$|++; # no buffering

my $udp_port = 6668;

socket( UDPSOCK, PF_INET, SOCK_DGRAM, getprotobyname('udp') ) or die "+socket: $!";

select( ( select(UDPSOCK), $|=1 )[0] ); # no buffering

setsockopt( UDPSOCK, SOL_SOCKET, SO_REUSEADDR, 1 )
    or die "setsockopt SO_REUSEADDR: $!";
#setsockopt( UDPSOCK, SOL_SOCKET, SO_BROADCAST, 1 )
#    or die "setsockopt SO_BROADCAST: $!";

# my $broadcastAddr = sockaddr_in( $udp_port, INADDR_BROADCAST );
my $broadcastAddr = sockaddr_in( $udp_port, INADDR_ANY );
bind( UDPSOCK, $broadcastAddr ) or die "bind failed: $!\n";

my $timeout = 10;
my $input;
while(1) {
    my $rin = '';
    vec($rin, fileno(UDPSOCK), 1) = 1;
    my ($nfound, $timeleft) = select($rin, undef, undef, $timeout);
    print "$timeleft\n";
    if ($nfound<1) {
        print "timeout\n";
        exit(0);
        }
    my $addr = recv( UDPSOCK, $input, 4096, 0 ) or die "+recv: $!";
#    print "$addr => $input\n";
    print "[$input]\n";
}
