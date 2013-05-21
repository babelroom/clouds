#!/usr/bin/perl

# ---
# dump an esteram
# ---

# ---
$|++;
use EStream;
#use URI::Escape;
#use REST::Client;

# ---
die "missing url or bad parameters" if $#ARGV!=0;
$url = $ARGV[0];

# ---
print "Connecting to [$url]\n";
$esh = estream_open("$url") or die;

# ---
sub msg
{
    my $length = shift;
    my $data = shift;
    my $ts = shift;

    print "[$ts]$data\n";
    return;

#print "[$ts]$data\n--\n";
#return;
#    foreach my $kv(split(/\r\n/, $data)) {
##print "$kv\n";
##print "2\n";
##        conference_action($1,$2,$3) if $kv =~ /^Conference-([^-]*)-([^:]+):[\s*](.*)$/;
##        recording_action($1,$2,$3) if $kv =~ /^Recording-([^-]*)-([^:]+):[\s*](.*)$/;
##        channel_action($1,$2) if $kv =~    /^Channel-([^_]*):[\s*](.*)$/;
##print "3\n";
#        print "--\n$kv\n";
#        }
}

# ---
my $data;
my $len;
my $timestamp = undef;
while(($len=estream_read_with_timestamp($esh,\$data,\$timestamp))) {
    msg($len, $data, $timestamp/10.0);
}

# ---
estream_close($esh) if $esh;

# ---
exit 0;

