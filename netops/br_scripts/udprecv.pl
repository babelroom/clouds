
# --- test BRUDP
use BRUDP;

# ---
my $bru = BRUDP->new(RecvPort=>6668) or die "$!";
my $result = $bru->recv('|foo|bar|', 20);
print "[$result]\n";

