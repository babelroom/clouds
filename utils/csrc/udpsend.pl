
# retain for reference 

use warnings;
use strict;

use Socket qw(:all);
use POSIX ":sys_wait_h";

socket( SOCKET, PF_INET, SOCK_DGRAM, getprotobyname("udp") )
    or die "Error: can't create an udp socket: $!\n";

select( ( select(SOCKET), $|=1 )[0] ); # no from buffering

my $broadcastAddr = sockaddr_in(6668, INADDR_BROADCAST );
setsockopt( SOCKET, SOL_SOCKET, SO_BROADCAST, 1 );

send( SOCKET, "no_assigned", 0,  $broadcastAddr )
    or die "Error sending: $!\n";

close SOCKET;

