package BRRate;

use Data::Dumper;

# ---
sub read_vars
{
    my $pat = shift;
    my %vars = ();
    foreach $kv (split /,/, $pat) {
        $vars{$1} = $2 if $kv=~/^([^=]*)=(.*)$/ or $kv=~/^(.+)()$/;
        }
    return \%vars;
}

# ---
sub write_vars
{
    my $vars = shift;
    my $result = '';
    foreach $k (keys %$vars) {
        $result .= ",$k=$vars->{$k}";
        }
    return $result;
}

# ---
sub time_fmt
{
    my $seconds = shift;
    return int($seconds/60) . 'm' . int($seconds%60) . 's';
}

# ---
sub rate_calc
{
    # TODO -- make this acceptable as line item for very small numbers
    my $rate = shift;
    return ($rate/1000000);
}

# ---
sub cost_calc
{
    my $rate = shift;
    my $seconds = shift;
    # microdollars_per_minute to cents_per_second ... divide by 600000 (or 100 then 6000)
    # +0.5 then int() is equivalent to round()
    return int( ((($rate/100) * $seconds) / 6000) + 0.5 );
}

# --- we add 0 to values here so perl knows it's a numeric
sub rate
{
    my ($vars, $accounting_code, $accounting_desc, $started, $number, $seconds, $plan_usage_in) = @_;
    my $data = $vars->{$accounting_code};
    if (not defined $data) {
        print STDERR "no known accounting_code '$accounting_code' in plan, dumping plan:\n" . Dumper($vars);
        die;
        }
    my ($rate,$threshold,$resolution) = split(/\//,$data,3);
    $rate = $vars->{$rate} if $rate=~/^\D/;
    $rate = ($rate+0);

    # **IMPORTANT** ignore must mean this row could NEVER create a charge, i.e. 
    # rate==0 can never create a charge
    # don't ignore just happens to return a 0 charge based on threshold or usages
    # because (amount other reasons) we may retry the charge for a different
    # plan_usages if the plan period cycles ...
    return (1,undef,undef,undef,undef,undef) if !$rate; # ignore
    my $threshold_pool = $accounting_code;
    if ($threshold=~/^\D/) {
        $threshold_pool = $threshold;
        $threshold = $vars->{$threshold};
        }
    $resolution = $vars->{$resolution} if $resolution=~/^\D/;
    $threshold = '0' if not defined $threshold;
    $resolution = '6000' if not defined $resolution;
    $resolution = int(($resolution+0)/1000);
#    print Dumper($rate,$threshold,$resolution);

    $seconds = ($seconds+0);
    my $tmp = ($seconds % $resolution);
    if ($tmp) {
        $seconds += ($resolution - $tmp);
        }

    # ---
    my $amount_in_cents = 0;
    my $description = '';
    my $overage_in_cents = 0;
    my $overage_desc = '';
    my $plan_usage_out = $plan_usage_in;
    if ($threshold ne '0') {
        my $pu = read_vars($plan_usage_in);
        my $old_usage = (($pu->{$threshold_pool})+0);
        my $current_usage = $old_usage + $seconds;
        my $threshold_in_seconds = ($threshold+0) * 60;
        if ($current_usage > $threshold_in_seconds) {
            # -- $started is the call started time, omitting is from the description, because
            # it's verbose and ugly, each invoice item has a date stamp anyhow and this
            # way we don't have to worry about the timezone :-)
            #$description = "$number $started GMT " . time_fmt($threshold_in_seconds-$old_usage) . " (in plan)";
            $description = "$accounting_desc / $number " . time_fmt($threshold_in_seconds-$old_usage) . " (in plan)";
            $seconds = $current_usage - $threshold_in_seconds;
            $current_usage = $threshold_in_seconds;
            $overage_in_cents = cost_calc($rate,$seconds);
            $overage_desc = "$accounting_desc / $number " . time_fmt($seconds) . " @ \$" . rate_calc($rate) . "/min (over plan)";
            }
        else {
            $description = "$accounting_desc / $number " . time_fmt($seconds) . " (in plan)";
            $seconds = 0;
            }
        $pu->{$threshold_pool} = $current_usage;
        $plan_usage_out = write_vars($pu);
        $amount_in_cents = 0;
        }
    else {
        $description = "$accounting_desc / $number " . time_fmt($seconds) . " @ \$" . rate_calc($rate) . "/min";
        $amount_in_cents = cost_calc($rate,$seconds);
        }

    return (0,$amount_in_cents,$description,$overage_in_cents,$overage_desc,$plan_usage_out);
}

# ---
sub do_test
{
    my $plan_data = read_vars(',tollfree=30000,domout=10000/0/60000,domin=9800/thres1,intlin=13000/thres1,thres1=2000,skype=50000/1000,sipin=0,three_ms=3000');
    my $accounting_code = 'free';
    my $seconds = '3600';
    my $accounting_code = 'domin';
    my $plan_usage_in = 'tollfree=0,thres1=119000';
    my $started = '2011-05-31 21:34:56';
    my $accounting_desc = 'Domestic Inbound';
    my $number = '14154498899';

    print Dumper(rate($plan_data,$accounting_code,$accounting_desc,$started,$number,$seconds,$plan_usage_in));
}

#do_test();
1;
