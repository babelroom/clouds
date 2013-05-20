#!/usr/bin/perl

use JSON qw( from_json );
use Data::Dumper;

$IK = '/home/br/ikeys'; 
%M = ();
%done = ();
$R = undef;
$D = 0;

# ---
$PDIR = '/home/br/gits/clouds/clouds/primers';
push @INC, $PDIR;

# ---
foreach my $f (<$IK/*>) {
    my $e = substr($f, length($IK)+1);
    open F, "<$f";
    my $c = <F>;
    chomp $c;
    close F;
    $M{$e} = $c;
}

# ---
sub eval_prime
{
    my $script = shift;
    delete $INC{$script};
    require "$script" or die;
}

# ---
sub copy_file
{
    my ($src, $dest, $mode) = @_;
    open IF, "<$src" or die $!;
    die 'Empty destination file' if not length($dest);
    open OF, ">$dest" or die $!;
    foreach(<IF>) {
        print OF $_;
        }
    close OF;
    chmod(oct($mode), $dest) if defined $mode;
    close IF;
}

# ---
sub recurse_prime
{
    my $k = shift;
    my $key = $k;
    my $c = $M{"$k"};
    die "primer predicate [$k] does not exist" if not defined $c;
    my $r = from_json($c, {allow_barekey => 1, allow_singlequote => 1, relaxed => 1});
    my ($src, $file, $script, $deps, $mode) = ($r->{src}, $r->{file}, $r->{script}, $r->{deps}, $r->{mode});
    if ($done{$k}) {
        print "key[$k] is done\n" if $D;
        return;
        }
    $done{$k} = 1;
    foreach $k (@$deps) {
        print "recurse_prime[$k]\n" if $D;
        recurse_prime($k);
        }
    $R = $r;
    if (defined $src) {
        print "copy_file[$key, $src, $file, $mode]\n" if $D;
        copy_file("$PDIR/$src", $file, $mode);
        }
    else {
        print "eval_prime[$key, $script]\n" if $D;
#print Dumper($R);
        eval_prime($script);
        }
}

# ---
while (my ($e, $c) = each %M) {
    next if not $e =~ /^prime_(.*)/;
    recurse_prime("prime_$1");
}

1;
