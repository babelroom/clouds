package BRUDP;

use strict;
use warnings;

use IO::Socket::INET;

# ---
sub new
{
    my $class = shift;
    my %a = @_;
    my ($r,$s) = ($a{Port} || $a{RecvPort}, $a{Port} || $a{SendPort});
    if ($r) {
        $r = new IO::Socket::INET->new(Proto=>'udp', LocalPort=>$r, ReuseAddr=>1) or return 0;
        }
    if ($s) {
        $s = new IO::Socket::INET->new(Proto=>'udp', PeerPort => $s, PeerAddr => '255.255.255.255', Broadcast => 1) or return 0;
        }
    return bless { r=>$r, s=>$s }, $class;
}

# ---
sub send
{
    my ($self, $verb) = (shift, shift);
    my $socket = $self->{s};
    $socket->send($verb) or return -1;
}

# ---
sub recv
{
    my ($self, $verbs, $timeout, $rin) = (shift, shift, shift, '');
    my $socket = $self->{r};
    vec($rin, fileno($socket), 1) = 1;
    my $data;
    while(1) {
        my ($nfound, $timeleft) = select($rin, undef, undef, $timeout);
        if (($nfound+0)<1) {
            # timeout
            return 1;
            }
        $socket->recv($data, 128) or return 0;
#        print "[$verbs][$data]\n";
        if (index("|$verbs|", "|$data|")!=-1) { # match substring
            return $data;
            }
        $timeout = $timeleft;
        }
}

# ---
sub DESTROY
{
    my $self = shift;
    if ($self->{r}) { $self->{r}->close(); }
    if ($self->{s}) { $self->{s}->close(); }
}

1;
