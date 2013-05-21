package EStream;

# FYI copied to eStream source tree - remove this comment if resolved

# ---
use IO::Socket::INET;
require(Exporter);
@ISA = qw(Exporter);
@EXPORT = qw(estream_open estream_read estream_read_with_timestamp estream_close);

# -- test stuff
#my $esh = estream_open(undef);
#my $esh = estream_open("");
#my $esh = estream_open("foo:23/more");
#my $esh = estream_open("https://foo/more");
#my $esh = estream_open("https://foo:23/more");
#my $esh = estream_open("http://foo/more");
#my $esh = estream_open("http://foo:/more");
#my $esh = estream_open("http://foo:23/more");
#my $esh = estream_open("http://foo:23");
#my $esh = estream_open(":23/more");
#my $esh = estream_open(":23");
#my $esh = estream_open("http://");
#my $esh = estream_open("http://foo");

# ---
sub url_parse
{
    my $url = shift;
    my $port = 80;
    my $host = '127.0.0.1';
    my $uri = '/';
    my $tmp = $url;
    $port = 443 if $tmp =~ s!^https://!!;
    $tmp =~ s!^http://!!;
    $host = $1 if $tmp =~ s!^([^:/]+)!!;
    $port = $1 if $tmp =~ s!^:([^/]+)!!;
    $uri = $tmp if $tmp =~ /^\//;
#    print "[$url]==[http://$host:$port$uri]\n";
    return ($host,$port,$uri);
}

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
    my $state = 0;  # 0==plain, 1==CR, 2==CRLF, 3==CRLFCR 
    my $content = '';
    my $char;
    while(1) {
        last if not read($socket,$char,1);
        $content .= $char;
        if (0) {}
        elsif ($state==0 && $char eq "\r") { $state=1; }
        elsif ($state==1 && $char eq "\n") { $state=2; }
        elsif ($state==2 && $char eq "\r") { $state=3; }
        elsif ($state==3 && $char eq "\n") {
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
sub headers_conform
{
    my $headers = shift;
    my $header_line = undef;
    my $is_chunked_encoding = 0;
    foreach my $l(split(/\r\n/, $headers)) {
        $header_line = $l if not defined $header_line;
#        print "[$l]\n";
        $is_chunked_encoding=1 if $l =~ /^Transfer-Encoding:\s*chunked/i;
        }
    if ($is_chunked_encoding and $header_line=~/^HTTP\/\d+\.\d+\s+2\d\d/)
        { return 1; }
#print "[$is_chunked_encoding]-[$header_line]foo\n";
    return 0;
}

# ---
sub read_length
{
    my $socket = shift;
    my $length_ref = shift;
    my $state = 0;  # 0==plain, 1==CR
    my $content = '';
    while(1) {
        last if not read($socket,$char,1);
        $content .= $char;
#print "char=[". $char ."], state=[" . $state . "]\n";
        if (0) {}
        elsif ($state==0 && $char eq "\r") { $state=1; }
        elsif ($state==1 && $char eq "\n") {
            $$length_ref = hex $content;
#print "len=[". $$length_ref ."]\n";
            return 1;
            }
        else {
            $state = 0;
            }
        }
    return 0;
}

# ---
sub estream_open
{
    my $url = shift;
    my ($host,$port,$uri) = url_parse($url);
    my $socket = new IO::Socket::INET->new(PeerAddr=>$host,PeerPort=>$port,Proto=>'tcp') or return 0;
#    print "[$url]==[http://$host:$port$uri]\n";
    my $headers;
    if ($socket->send("GET $uri HTTP/1.0\r\n\r\n") and read_headers($socket,\$headers) and headers_conform($headers)) {
        return $socket;
        }
    close($socket);
    return 0;
}

# ---
sub estream_read
{
    my $socket = shift;
    my $result_ref = shift;
    my $len;
    read_length($socket,\$len) or return 0;
    die if $len<0;
    die if not $len;
    my $remaining = $len;
    my $data;
    $$result_ref = '';
    while($remaining) {
        # TODO: according to perl docs. read() returns undef on error
        my $result = read($socket,$data,$remaining);
        last if not $result;
        die if $result<0;
        $$result_ref .= $data;
        $remaining -= $result;
        }
    die if $remaining;
    die if read($socket,$data,2)!=2;
    return $len-$remaining;
}

# ---
sub estream_read_with_timestamp
{
    my $socket = shift;
    my $result_ref = shift;
    my $timestamp_ref = shift;
    my $retval = estream_read($socket, $result_ref);
    return $retval if ($retval<0);
    if ($$result_ref =~ /^([a-f0-9]+)(.*)$/) {
        my $ts = $1;
        $$result_ref = $2;
        $retval = length($$result_ref);
        if (length($ts)>4) {
            $$timestamp_ref = hex($ts);
            }
        elsif (defined $$timestamp_ref) {
            $$timestamp_ref += hex($ts);
            }
        }
    return $retval;
}

# ---
sub estream_close
{
    my $socket = shift;
    close($socket);
    return 1;
}

1;
