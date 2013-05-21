#!/usr/bin/perl

# ---
#BR_description: Remove or delete conference artifacts from a server and otherwise close out
#BR_startup: running=always
#BR__END: 
# ---

# ---
$|++;
use BRDB;

# ---
$dbh = db_quick_connect();

# ---
for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) 
{
    # TODO: actually do stuff ...
    db_exec($dbh,"UPDATE conferences SET state='closed' WHERE state='media_done'",'_updated') or die;
    print "Closed $_updated conference(s)\n" if ($_updated);

    # ---
    sleep $ENV{BR_SLEEP_LONG};
}

# ---
db_disconnect($dbh);

exit 0;

