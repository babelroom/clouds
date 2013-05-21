package BRFS;

# ---
use IO::Socket::INET;

# ---
# NB, this byte-at-a-time approach to reading headers and
#   data lengths is obviously wasteful. Headers are once off
#   and perl is notoriously bad for exact data length operations
#   (but good for patterns). Maybe review at some point. Maybe
#   make a custom estream format.
# ---
sub read_headers
{
    my $socket = shift;
    my $content_ref = shift;
    my $state = 0;  # 0==plain, 1==CR
    my $content = '';
    my $char;
    while(1) {
        last if not read($socket,$char,1);
        $content .= $char;
        if (0) {}
        elsif ($state==0 && $char eq "\n") { $state=1; }
        elsif ($state==1 && $char eq "\n") {
            # done -- the entire header block is now in $content
            $$content_ref = $content;
            return 1;
            }
        else {
            $state = 0;
            }
        }
    return 0;
}

# ---
sub parse_headers
{
    my $headers = shift;
    my $vars_ref = shift;
    %{$vars_ref} = ();
    foreach my $l(split(/\n/, $headers)) {
        next if not $l =~ /^([^:]*):\s*(.*)$/;
        ${$vars_ref}{$1} = $2;
        }
    return 1;
}

# ---
sub read_response_headers
{
    my $socket = shift;
    my $vars_ref = shift;
    my $headers = '';
    return 0 if not read_headers($socket, \$headers);
    return 0 if not parse_headers($headers, $vars_ref);
    return 1;
}

# ---
sub read_auth_request
{
    my $socket = shift;
    my %vars = ();
    return 0 if not read_response_headers($socket, \%vars) or $vars{'Content-Type'} ne 'auth/request';
    return 1;
}

# ---
sub read_any_body
{
    my $socket = shift;
    my $vars_ref = shift;
    my $data_ref = shift;
    my %vars = %$vars_ref;
    my $len = $vars{'Content-Length'};
    my $data = undef;
    if (not defined $len) {
        $data = $vars{'Reply-Text'};
        return 0 if not defined $data;
        $$data_ref = $data;
        return 1;
        }
    $len = $len+0;
    return 1 if $len==0;
    my $toread = $len;
    $$data_ref = '';
    while($toread>0) {
        $data = '';
        my $justread = read($socket,$data,$toread);
        if (not defined $justread) {
            print STDERR "read() error: $!\n";
            return 0;
            }
        $toread -= $justread;
        $$data_ref .= $data;
        }
    return 1;
}

# ---
sub cmd_and_response
{
    my $socket = shift;
    my $cmd = shift;
    my $data_ref = shift;
    my %vars = ();
    return 0 if not $socket->send("$cmd\n\n") or not read_response_headers($socket, \%vars) or not read_any_body($socket, \%vars, $data_ref);
    return 1;
}

# ---
sub open
{
    my $host = shift;
    my $port = shift;
    my $authpw = shift;
    my $socket = new IO::Socket::INET->new(PeerAddr=>$host,PeerPort=>$port,Proto=>'tcp');
    return undef if not $socket;
    if (read_auth_request($socket) and cmd_and_response($socket, "auth $authpw", undef)) {
        return $socket;
        }
    close($socket);
    return undef;
}

# ---
sub close
{
    my $socket = shift;
    close($socket);
    return 1;
}

# --- 
$sock = undef;
sub fs_cmd_with_retry
{
    my $host = shift;
    my $port = shift;
    my $authpw = shift;
    my $cmd = shift;
    my $data_ref = shift;
    while(true) {
        if (not defined($sock)) {
            $sock = BRFS::open($host,$port,$authpw);
            }
        if (defined($sock)) {
            if (BRFS::cmd_and_response($sock, $cmd, $data_ref)) {
                return 1;
                }
            BRFS::close($sock);
            $sock = undef;
            }
        if (not defined($sock)) {
            print STDERR "Connection error, retrying...\n";
            }
        sleep 1;
        }
}

1;
