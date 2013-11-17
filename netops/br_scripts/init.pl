#!/usr/bin/perl

# ---
$|++;
use DBI; # transitioning to BRDB
use BRDB;
use POSIX ":sys_wait_h";
use POSIX qw<dup2>;

# ---
$ENV{PATH} = '.:' . $ENV{PATH};










# ---
#   = C o n f i g u r e   E n v i r o n m e n t   H e r e ! =
#
# setup environment for this and child scripts
#   this is the place to set all environment/configuration variables
# ---
$ENV{BR_DBUSER} = 'root';
$ENV{BR_DBPASS} = '';
$ENV{BR_SLEEP_SHORT} = 12000;
$ENV{BR_SLEEP_LONG} = 120;
$ENV{BR_ITERATIONS} = 720;
$ENV{BR_UDPPORT} = 6668;

# --- customize environment here
#$ENV{BR_ENVIRONMENT} = 'development';
#$ENV{BR_ENVIRONMENT} = 'staging';
$ENV{BR_ENVIRONMENT} = 'production';

# ---
if ($ENV{BR_ENVIRONMENT} eq 'development') {
    $ENV{BR_INSTALL_DIR} = '/home/jroy/gits/clouds/netops';
    $ENV{BR_DSN} = 'dbi:mysql:netops_development:127.0.0.1:3306';
    }
elsif ($ENV{BR_ENVIRONMENT} eq 'staging') {
    $ENV{BR_INSTALL_DIR} = '/home/br/gits/clouds/netops';
    $ENV{BR_DSN} = 'dbi:mysql:netops_staging:127.0.0.1:3306';	# staging
    }
elsif ($ENV{BR_ENVIRONMENT} eq 'production') {
    $ENV{BR_INSTALL_DIR} = '/home/br/gits/clouds/netops';
    $ENV{BR_DSN} = 'dbi:mysql:netops:127.0.0.1:3306';	# production
    }
else {
    die "unknown environment: $ENV{BR_ENVIRONMENT}\n";
    }

$ENV{BR_MAIL_TEMPLATE_DIR} = $ENV{BR_INSTALL_DIR} . '/email_templates';
$ENV{BR_LOGDIR} = $ENV{BR_INSTALL_DIR} . '/log';
# --- end of BR environment





# --- globals
$dbh = undef;
%child_status = ();
@dead_processes = ();
$dsn = $ENV{BR_DSN};
$dbuser = $ENV{BR_DBUSER};
$dbpass = $ENV{BR_DBPASS};
%job = undef;
%job_pid_id_map = ();

# --- just refreshing scripts in db? exec sync.pl
if ($ARGV[0] eq '-u') { # -- this is somewhat depreciated at this point
    exec('sync.pl') or die "Could not exec sync.pl: $!\n";
    die "why am I still here?\n";
    }

# ---
if (-t STDOUT) {
    # redirect STDOUT to /dev/null
    open(STDOUT, '>', '/dev/null') or die $!;
    # -- interactive mode, need to respawn ourself, then monitor and restart init.pl as needed
    # --- write pid file
    `echo $$ >/var/tmp/netops.pid`;
    do {
        db_do_connect();
        clear_old_jobs();
        insert_init_job();
        get_init_job();
        do_a_job() or die "$!\n";
        db_do_disconnect();
        while(waitpid($job{pid},0)!=$job{pid}) { sleep 10; }
        sleep 5;    # stop any busy loops
        } while(1);
    exit 0;
}

# --- only now install the reaper
$SIG{CHLD} = \&REAPER;

# ---
# only need this if fork'ing child processes
# ---
sub REAPER {
    my $child;
    while (($child=waitpid(-1,WNOHANG))!=-1) {
        last if not $child;
        $child_status{$child} = "$? -- ${^CHILD_ERROR_NATIVE}";
        push @dead_processes, $child;
        print "reaped [$child]\n";
        }
    $SIG{CHLD} = \&REAPER;  
}

# ---
sub db_do_connect
{
    while(1) {
        $dbh = db_connect($dsn,$dbuser,$dbpass,'LOCAL');
        return if $dbh;
        my $secs = 10;
        print "failed to connect to DB, retrying in $secs seconds\n";
        sleep($secs);
        warn "Trying DB re-connect...\n";
        }
}

# ---
sub db_do_disconnect
{
    db_disconnect($dbh);
}

# ---
sub db_do_exec
{
    my $sql = shift;
    my $stmt = $dbh->prepare($sql);
# TODO: saw a duplicate row error here once ...
#DBD::mysql::st execute failed: Subquery returns more than 1 row at ./init.pl line 125.
#DB: execute failed:  [INSERT INTO logs (name,`table`,id_in_table,content_type,path,created_at,updated_at) VALUES ('28718.log','jobs',(SELECT id FROM jobs WHERE pid='28718'),'text/plain','/home/jroy/gits/netops/log/28718.log',NOW(),NOW())]
# ... likely related to the pid's on the system cycling ...
    if ($stmt->execute()) {
        $stmt->finish();
        return 1;
        }
    else {
        $stmt->finish();
        warn "DB: execute failed: $DBI::errstr [$sql]\n";
        return 0;
        }
}

# ---
sub update_process_terminated
{
    my $pid = shift;
    my $status = $child_status{$pid};
    my $id = $job_pid_id_map{$pid};
    $job_pid_id_map{$pid} = undef;
    $child_status{$pid} = undef;
    print "process [$pid] has terminated, updating DB (id=$id)\n";
    my $sql = "UPDATE jobs SET status='$status',ended=NOW(),updated_at=NOW() WHERE id=$id";
    if (db_do_exec($sql)) {
        return 1;
        }
    else {
        warn "DB: execute failed: $DBI::errstr [$sql]\n";
        return 0;
        }
}

# ---
sub update_terminated_jobs
{
    my $pid;
    my @pids = ();
    my $sql = "SELECT id, pid FROM jobs WHERE pid IS NOT NULL AND ended IS NULL";
    my $stmt = $dbh->prepare($sql);
    if ( not defined $stmt->execute()) {
        warn "DB: execute failed: $DBI::errstr [$sql]\n";
        return 0;
        }
    my $result = 0;
    while(my(@data)=$stmt->fetchrow_array) {
        $pid = $data[1];
        if (not kill 0, $pid) {
#print "id=$data[0], pid=$data[1]\n";
            $job_pid_id_map{$pid} = $data[0];
            $child_status{$pid} = 'unknown';
            push @pids, $pid;
            }
    }
    $stmt->finish();
    foreach $pid (@pids) {
        update_process_terminated($pid);
        }
}

# ---
sub get_a_job
{
    my $sql = "SELECT id, script_name, parameters FROM jobs WHERE pid IS NULL ORDER BY updated_at LIMIT 1";
    my $stmt = $dbh->prepare($sql);
    if ( not defined $stmt->execute()) {
        warn "DB: execute failed: $DBI::errstr [$sql]\n";
        return 0;
        }
    my $result = 0;
    while(my(@data)=$stmt->fetchrow_array) {
        %job = ();
        $job{id} = $data[0];
        $job{name} = $data[1];
        $job{parameters} = $data[2];
        $result = 1;
    }
    $stmt->finish();
    return $result;
}

# ---
sub get_init_job
{
    my $pid = $$;
    my $sql = "SELECT id, script_name, parameters FROM jobs WHERE pid = '$pid'";
    my $stmt = $dbh->prepare($sql);
    if ( not defined $stmt->execute()) {
        warn "DB: execute failed: $DBI::errstr [$sql]\n";
        return 0;
        }
    my $result = 0;
    while(my(@data)=$stmt->fetchrow_array) {
        %job = ();
        $job{id} = $data[0];
        $job{name} = $data[1];
        $job{parameters} = $data[2];
        $result = 1;
    }
    $stmt->finish();
    return $result;
}

# ---
sub do_symlink
{
    my $lf = shift;
    my $name = shift;
    my $suffix = shift;
    my $ln = "$ENV{BR_LOGDIR}/$name$suffix";
    unlink $ln if -l $ln;
    symlink $lf, $ln;
}
# ---
sub set_filenames
{
    my $pid = shift;
    my $name = shift;
    $job{"STDOUT.name"} = $pid . ".log";
    $job{"STDERR.name"} = $pid . ".err";
    $job{STDOUT} = $ENV{BR_LOGDIR} . "/" . $job{"STDOUT.name"};
    $job{STDERR} = $ENV{BR_LOGDIR} . "/" . $job{"STDERR.name"};
    do_symlink($job{'STDOUT.name'}, $name, ".log");
    do_symlink($job{'STDERR.name'}, $name, ".err");
}

# ---
sub my_dup2
{
    my $handle = shift;
    my $fh = shift;
    my $filename = $job{$handle};
    my $newhandle = "my.$handle";
    open $newhandle, '+>', "$filename";
    dup2(fileno $newhandle, $fh);
}

# ---
sub spawn_job
{
    local $id = $job{id};
    local $name = $job{name};
    local $parameters = $job{parameters};
    local $pid = fork();
    if ($pid==-1) {
        warn "fork() failed: $!\n";
        return -1;
        }
    elsif ($pid) {  # parent
        $job_pid_id_map{$pid} = $id;
        $job{pid} = $pid;
        set_filenames($pid,$name);
        return $pid;
        }
    else {  # child
        $pid = $$;
        $ENV{BR_PARAMETERS} = $parameters;
        set_filenames($pid,$name);
        close STDIN;
        close STDOUT;
        close STDERR;
        my_dup2(STDOUT, 1);
        my_dup2(STDERR, 2);
        exec($name);
        die "exec failed:$!\n"
        }
}

# ---
sub insert_init_job
{
    local $id = shift;
    local $pid = $$;
    db_do_exec("INSERT INTO jobs (name,script_name,pid,parameters,started) VALUES ('$0', '$0', '$$', '', NOW());");
}

# ---
sub clear_old_jobs
{
    local $id = shift;
    local $pid = $$;
    db_do_exec("UPDATE jobs SET status='cleared',ended=NOW(),updated_at=NOW() WHERE ended IS NULL");
}

# ---
sub update_job_pid
{
    local $id = $job{id};
    local $pid = $job{pid};
    db_do_exec("UPDATE jobs SET pid='$pid', started=NOW() WHERE id=$id");
}

# ---
sub insert_file_record
{
    my $handle = shift;
    my $name = $job{"$handle\.name"};
#    db_do_exec("INSERT INTO logs (name,`table`,id_in_table,content_type,path,created_at,updated_at) VALUES ('$name','jobs',(SELECT id FROM jobs WHERE pid='$job{pid}'),'text/plain','$job{$handle}',NOW(),NOW())")
    db_do_exec("INSERT INTO logs (name,`table`,id_in_table,content_type,path,created_at,updated_at) VALUES ('$name','jobs','$job{id}','text/plain','$job{$handle}',NOW(),NOW())")
        or return 0;
}

# ---
sub do_a_job
{
    db_do_disconnect();
    spawn_job();
    db_do_connect();
    return 0 if $job{pid} < 0;
    update_job_pid();
    insert_file_record(STDOUT);
    insert_file_record(STDERR);
    print "Spawned job $job{name}, pid [$job{pid}] stdout,stderr $job{STDOUT},$job{STDERR}\n";
}

# ---
sub added_jobs
{
    $added_a_job = 0;
    $always = [];
    db_select("SELECT * FROM scripts WHERE is_deleted IS NULL AND startup = '**scheduler**'",'always',$dbh) or return 0;
    return 0 if $#{$always} == -1;
    my $job_names = "''";
    foreach my $r (@{$always})
        { $job_names.=qq!,'$r->{name}'!; }
    $running = [];
    db_select("SELECT id,name,ended FROM jobs WHERE ended IS NULL AND name IN ($job_names)",'running',$dbh) or return 0;
    my %running_hash = ();
    foreach my $r (@{$running}) {
        print "Add running [$r->{name}, $r->{id}]\n";
        $running_hash{$r->{name}} = $r->{id};
        }
    foreach my $r (@{$always}) {
        next if defined $running_hash{$r->{name}};
        $name = $dbh->quote($r->{name});
        $parameters = $dbh->quote($r->{name});
        db_exec($dbh,"INSERT INTO jobs (name,script_name,parameters,created_at,updated_at) VALUES ($name, $name, $parameters, NOW(), NOW());") or return 0;
        $added_a_job = 1;
        }
    return $added_a_job;
}

# ---
print "init.pl: now running as pid [$$]\n";

# ---
db_do_connect();
update_terminated_jobs();
db_do_disconnect();

# ---
#for(my $it=0; $it<$ENV{BR_ITERATIONS}; $it++) {
for(my $it=0; 1; $it++) {
    db_do_connect();
again:
    while($#dead_processes>-1) {
        my $pid = shift @dead_processes;
        next if not defined $job_pid_id_map{$pid};  # child started and terminated before we returned from fork()
        update_process_terminated($pid);
        }

    my $did_something = 0;

    if (get_a_job()) {
        do_a_job();
        $did_something = 1;
        }

    if (added_jobs()) {
        $did_something = 1;
        }

    if ($did_something)
        { goto again; }

    db_do_disconnect();
# ---
# wait for notification that an update occurs to the running scripts
# table 
# ---
##open F, "/usr/bin/curl -N -s wanchai/conference/$cid.fs?fmt=1 |";
##$old_data = '';
##exit 0;
    sleep $ENV{BR_SLEEP_SHORT}; # later add estream
}

db_do_disconnect();

exit 0;

