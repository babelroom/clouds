
# --- test BRUDP
use BRUDP;

# ---
my $msg = $ARGV[0];
my $bru = BRUDP->new(SendPort=>6668) or die "$!";
my $result = $bru->send($msg);

