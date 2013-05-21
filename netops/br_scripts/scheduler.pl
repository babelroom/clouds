#!/usr/bin/perl

# ---
$|++;
use BRDB;
use BRJobs;

# ---
#BR_description: This is the main 'cron' scheduler
#BR_startup: **scheduler**
#BR__END: 
# ---

# ---
$g_last_minute = 0;
@g_this_time = ();

# ---
die if not ($dbh = db_quick_connect());

# ---
sub get_all_scripts {
    $all_scripts = [];
    db_select("SELECT name,startup FROM scripts WHERE is_deleted IS NULL",'all_scripts',$dbh) or return 0;
}

# ---
sub match_interval
{
    my $pat = shift;
    my $value = shift;
#print "M $pat==$value ????\n";
    return 1 if $pat eq '*';
    return 1 if $value == ($pat+0);
    return 0;
}

# ---
sub match
{
    my $cron_string = shift;
#    my $cron_string = '1 * * * *';

    # @g_this_time
    # --- seconds(0..59), minute(0..59), hour(0..23), mday (1..31), month(0..11), year, wday (0..6) (starts Sunday), yday, isdst

    # --- minute,hour,day in month, month, day in week
    if ($cron_string !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
        print STDERR "bad cron time pattern [$cron_string]\n";
        return undef;
        }
    my ($min,$hour,$mday,$month,$wday) = ($1,$2,$3,$4,$5);
    my $t = join('-',@g_this_time);
    if (    1   &&
            match_interval($min,$g_this_time[1])   &&
            match_interval($hour,$g_this_time[2])   &&
            match_interval($mday,$g_this_time[3])   &&
            match_interval($month,$g_this_time[4])   &&
            match_interval($wday,$g_this_time[6])   &&
        1 ) {
        print "localtime ($t) matched scheduled time $cron_string\n";
        return 1;
        }
    else {
#        print "localtime ($t) does not match scheduled time $cron_string\n";
        }
    return 0;
}

# ---
sub scheduled
{
    my $cron_string = shift;
    return 1 if $cron_string =~ /always/;
    return 0 if $cron_string =~ /manual/;
    return 0 if $#g_this_time<0;
    return match($cron_string);
}

# ---
sub find_scripts {
    my $system_type = shift;
#    my $access_pattern = shift;
    my $required_key = shift;
    $_systems = [];
    db_select("SELECT id,name,access FROM systems WHERE system_type LIKE '%".$system_type."%\'",'_systems',$dbh) or return 0;
    # -- interpolate
    foreach my $r(@{$_systems}) {
        my %vars = ();
        foreach my $kv(split /,/, $r->{access}) {
            if ($kv=~/^([^=]*)=(.*)$/) {
                $vars{$1} = $2;
                next;
                }
            $vars{$kv} = '';
            }
        next if defined $vars{disabled};
#        next if $r->{access} !~ /$access_pattern/;  # skip if access doesn't match
        next if not defined $vars{$required_key};
        foreach my $s(@{$all_scripts}) {
            next if $s->{startup} !~ /^foreach_${system_type}=\s*(.*)$/;  # skip if script isn't requested for each system of the appropriate type
            next if not scheduled($1);
            my $name = "$s->{name} - ($r->{id}-$r->{name})";
            $systems{$name} = $r;
            $script_names{$name} = $s->{name};
            }
        }
    return 1;
}

# ---
sub find_always_scripts {
    foreach my $s(@{$all_scripts}) {
        next if $s->{startup} !~ /^running=\s*(.*)$/;
        next if not scheduled($1);
        my $name = $s->{name};
        $systems{$name} = $s;
        $script_names{$name} = $s->{name};
        }
}

# ---
sub prune_running_scripts {
    my $names = "''";
    foreach my $n (keys %script_names)
        { $names .= ",".$dbh->quote($n); }
    $_j = [];
    jobs_find($dbh,'_j',$names);
    foreach my $j(@{$_j}) {
        $systems{$j->{name}} = undef;
        $script_names{$j->{name}} = undef;
        }
}

# ---
sub launch_system_specific_scripts {
    my $jobs = 0;
    foreach my $n(keys %script_names) {
        my $script_name = $script_names{$n};
        next if not defined $script_name;
        my $s = $systems{$n};
        die if not defined $s;
        job_launch($dbh,$n,$script_name,"$s->{access},system_id=$s->{id}") and $jobs++;
        }
    return $jobs;
}

# ---
sub launch_scripts {
    my $jobs = 0;
    foreach my $n(keys %script_names) {
        my $script_name = $script_names{$n};
        next if not defined $script_name;
        job_launch($dbh,$n,$script_name,"") and $jobs++;
        }
    return $jobs;
}

# ---
for(my $i=0; $i<$ENV{BR_ITERATIONS}; $i++) {

    # --- make sure scheduled tasks only run once every minute, max
    my $this_minute = int(scalar(time)/60);
    if ($this_minute==$g_last_minute) {
        @g_this_time = ();
        print "Not checking for scheduled jobs\n";
        }
    else {
        $g_last_minute = $this_minute;
        @g_this_time = localtime();
        print "Checking for scheduled jobs\n";
        }
    
    # ---
    my $did_something = 0;
    get_all_scripts();

    # --- provisioning systems
    %systems = ();
    %script_names = ();
    find_scripts('provisioning','dsn');
    prune_running_scripts();
    if (launch_system_specific_scripts()) {
        $did_something = 1;   # iterate again, without delay
        }

    # --- rd systems
    %systems = ();
    %script_names = ();
    find_scripts('record_and_deliver','dsn');
    prune_running_scripts();
    if (launch_system_specific_scripts()) {
        $did_something = 1;   # iterate again, without delay
        }

    # --- freeswitch systems
    %systems = ();
    %script_names = ();
    find_scripts('freeswitch','ipv4');
    prune_running_scripts();
    if (launch_system_specific_scripts()) {
        $did_something = 1;   # iterate again, without delay
        }

    # --- always scripts
    %systems = ();
    %script_names = ();
    find_always_scripts();
    prune_running_scripts();
    if (launch_scripts()) {
        $did_something = 1;   # iterate again, without delay
        }

    # ---
    if ($did_something) {
#        sleep $ENV{BR_SLEEP_SHORT};
        sleep 1;    # just enough to stop an accidental busy loop
        }
    else {
        #sleep $ENV{BR_SLEEP_LONG};
        sleep $ENV{BR_SLEEP_SHORT};
        }
}

db_disconnect($dbh);

# ---
exit 0

