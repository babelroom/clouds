#!/usr/bin/perl

# ---
#BR_description: Internal do not use
#BR_startup: hidden
#BR__END:
# ---

# ---
use DBI;
use BRDB;
use POSIX;  # for strftime

# --- globals
$dbh = undef;
$dsn = $ENV{BR_DSN};
$dbuser = $ENV{BR_DBUSER};
$dbpass = $ENV{BR_DBPASS};

# ---
sub db_my_connect
{
#    $dbh = DBI->connect($dsn, $dbuser, $dbpass)
#        or warn "DB: connect failed: $DBI::errstr\n";
    $dbh = db_connect($dsn,$dbuser,$dbpass,'LOCAL');
    return $dbh;
}

# ---
sub db_my_disconnect
{
#    $dbh->disconnect
#        or warn "DB: disconnect failed: $DBI::errstr\n";
    db_disconnect($dbh);
}

# ---
%files = ();
%db_files = ();

# ---
sub read_dir
{
    my $dir = shift;

    # --- check scripts
    my $file;
    foreach $file (<$dir/*>) {
        if (-d $file) {
            read_dir($file);
            }
        else {
            next if not -f $file or not -x $file;
            my @stat = stat $file;
            $file = substr($file, 2);
            $files{$file} = POSIX::strftime("%Y-%m-%d %H:%M:%S",localtime($stat[9]));
#print "$files{$file}\n";
            }
        }
}

# ---
sub read_db
{
    $sql = "SELECT id, name, version FROM scripts WHERE is_deleted IS NULL ORDER BY version";
    $stmt = $dbh->prepare($sql);
    if ( not defined $stmt->execute()) {
        warn "DB: execute failed: $DBI::errstr [$sql]\n";
        return 0;
        }
    while(my(@data)=$stmt->fetchrow_array) {
        for (0..$#data) {
            $db_file_ids{$data[1]} = $data[0];
            $db_files{$data[1]} = $data[2];
            }
        }
    return 1;
}

# ---
sub archive_file
{
    my $file = shift;
    my $path;
    my $filename;
    if ($file=~/\//) {
        $file =~ /^(.*)\/([^\/]*)$/;
        $path = ".imported/$1";
        $filename = $2;
        }
    else {  
        $path = ".imported";
        $filename = $file;
        }
    `/bin/mkdir -p $path`;
    my $timestamp = $files{$file};
    $timestamp =~ tr/,:/__/;
#print "\t`/bin/cp $file '$path/$filename.$timestamp'`\n";
    `/bin/cp $file '$path/$filename.$timestamp'`;
}

# ---
%md = ();
sub read_metadata
{
    my $file = shift;
    %md = ();
    open FH, "<$file";
    foreach(<FH>) {
        chomp;
#print "[$_]\n";
        if (/^#\s*BR_([^:]+):\s*(.*)$/) {
            my $key = $1;
            my $val = $2;
            last if $key eq '_END';
            $md{$key} = $val;
#print "key=$key, val=$val\n";
            }
        }
    close FH;
}

# ---
sub new_file
{
    my $file = shift;
    archive_file($file);
#print "new_file = $file\n";
    read_metadata($file);
    my $name=$dbh->quote($file);
    my $version=$dbh->quote($files{$file});
    my $description=$dbh->quote($md{description});
    my $startup=$dbh->quote($md{startup});
    $sql = "INSERT INTO scripts (name,version,description,startup,created_at,updated_at) VALUES ($name,$version,$description,$startup,NOW(),NOW())";
    $stmt = $dbh->prepare($sql);
    $stmt->execute()
        or warn "DB: execute failed: $DBI::errstr [$sql]\n";
}

# ---
sub modified_file
{
    my $file = shift;
    archive_file($file);
#print "modified_file = $file\n";
    read_metadata($file);
    my $version=$dbh->quote($files{$file});
    my $description=$dbh->quote($md{description});
    my $startup=$dbh->quote($md{startup});
    $sql = "UPDATE scripts SET version=$version,description=$description,startup=$startup,updated_at=NOW() WHERE id=$db_file_ids{$file}";
    $stmt = $dbh->prepare($sql);
    $stmt->execute()
        or warn "DB: execute failed: $DBI::errstr [$sql]\n";
}

# ---
sub deleted_file
{
    my $file = shift;
#print "deleted_file = $file\n";
    $sql = "UPDATE scripts SET is_deleted=1, updated_at=NOW() WHERE id=$db_file_ids{$file}";
    $stmt = $dbh->prepare($sql);
    $stmt->execute()
        or warn "DB: execute failed: $DBI::errstr [$sql]\n";
}

# --- read files
read_dir('.');

# ---
db_my_connect() or die;

# --- get scripts in database
read_db() or die;

# --- new files
foreach $file (keys %files) {
    next if defined $db_files{$file};
    new_file($file);
}
# --- modified
foreach $file (keys %files) {
    next if not defined $db_files{$file};
    next if $files{$file} eq $db_files{$file};
    modified_file($file);
}
# --- deleted files
foreach $file (keys %db_files) {
    next if defined $files{$file};
    deleted_file($file);
}

# ---
db_my_disconnect();

# ---
exit 0;

