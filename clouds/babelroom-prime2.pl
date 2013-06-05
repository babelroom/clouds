#!/usr/bin/perl

$BR = "/home/br";
$IK = "$BR/ikeys";
`mkdir -p $IK`;
open OK, ">>$BR/ikeys.txt";

@md_keys = (
    'ami-id',
    'ami-launch-index',
    'ami-manifest-path',
    'ancestor-ami-ids',
#    print_block-device-mapping,
    'instance-id',
    'instance-type',
    'local-hostname',
    'local-ipv4',
    'kernel-id',
    'placement',
    'product-codes',
    'public-hostname',
    'public-ipv4',
#    print_public-keys,
    'ramdisk-id',
    'reservation-id',
    'security-groups',
);
%data = ();

# ---
sub write_kv
{
    my ($key,$val) = @_;
    $data{$key} = $val;
#    print "$key: $val\n";
    open OF, ">$IK/$key";
    print OF $val;
    print OK "$key: $val\n";
    close OF;
}

# --- determine if we might be on amazon ec2 -- this code is meant to error towards true (false positive rather than false negative)
`curl -fs http://169.254.169.254/`;
my $rc = (($? & 0xff00) >> 8);  # rc from curl, 0 on success, else its error code (1 for bad scheme, 255 if no curl)
my $ec2 = ($rc !=7);            # 7 is the error code we expect on a non-ec2 system. We could also check for ==0 here, but that might snag a different transitory error ??

# ---
my $ud = '';
if ($ec2) {
    foreach my $key (@md_keys) {
        $val = `curl -fs http://169.254.169.254/latest/meta-data/$key`;
        write_kv($key,$val);
    }
    $ud = `curl -fs http://169.254.169.254/latest/user-data`;
}
if (length($ud)==0) {
    # either not amazon or amazon without user-data -- get it from last br config write 
#    `/home/br/gits/clouds/utils/br` if not -f '/home/br/config'; not sure this is a good idea or not
    $ud = `cat /home/br/config`;
}
write_kv('user-data',$ud);
foreach my $line (split /\n/, $data{'user-data'}) {
    chomp($line);
    next if $line =~ /^\s*#/;
    next if $line =~ /^\s*$/;
    my ($key, $val) = split /:\s*/, $line, 2; 
    write_kv($key,$val);
}
close OK;

