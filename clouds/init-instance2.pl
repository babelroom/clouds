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

# ---
foreach my $key (@md_keys) {
    $val = `curl -fs http://169.254.169.254/latest/meta-data/$key`;
    write_kv($key,$val);
}
my $ud = `curl -fs http://169.254.169.254/latest/user-data`;
#my $ud = `cat /home/br/gits/clouds/clouds/user_data_example`;
write_kv('user-data',$ud);
foreach my $line (split /\n/, $data{'user-data'}) {
    chomp($line);
    next if $line =~ /^\s*#/;
    next if $line =~ /^\s*$/;
    my ($key, $val) = split /:\s*/, $line, 2; 
    write_kv($key,$val);
}
close OK;

