package BRJobs;

# ---
use BRDB;
require(Exporter);
@ISA = qw(Exporter);
@EXPORT = qw(job_find jobs_find job_launch);

# ---
sub job_find
{
    my $handle = shift;
    my $job_name = shift;
    db_select("SELECT id,name,ended FROM jobs WHERE ended IS NULL AND name = '$job_name'",'_res',$handle) or return 0;
    return ($#{$_res}>-1);
}

# ---
sub jobs_find
{
    my $handle = shift;
    my $result_var = shift;
    my $job_names = shift;
    db_select("SELECT id,name,ended FROM jobs WHERE ended IS NULL AND name in ($job_names)",$result_var,$handle) or return 0;
    return $#{$_res}+1;
}

# ---
sub job_launch
{
    my $handle = shift;
    my $name = shift;
    my $script_name = shift;
    my $parameters = shift;
    $name = $handle->quote($name);
    $script_name = $handle->quote($script_name);
    $parameters = $handle->quote($parameters);
    db_exec($handle,"INSERT INTO jobs (name,script_name,parameters,created_at,updated_at) VALUES ($name, $script_name, $parameters, NOW(), NOW());",'_updated');
    return ($_updated>0) ? 1 : 0;
}

1;

