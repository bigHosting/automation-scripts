#!/usr/bin/perl

#(C) Security Guy

use strict;
use warnings;
use DBI;                                                    # mysql
use File::Temp qw/ tmpnam /;                                # used by tmpnam() function
use Sys::Hostname;                                          # used by hostname() function
use File::Copy;                                             # used by move() function

# no buffering
$|=1;

BEGIN {
    use constant VERSION    => "0.7";
    use constant RELDATE    => "2014.12.22";
    use constant BY         => "Security Team";
    use constant USER       => "backup";
    use constant MYSQLHOST  => "localhost";
    use constant PWD        => '*****';
    use constant DESTFOLDER => "/localservices/backup/mysql";
    use constant MYSQLDUMP  => '/usr/bin/mysqldump';
    use constant GZIP       => '/bin/gzip';
    use constant MAX_DAYS   => 14;
}

sub rmkdir;
sub delete_files_older_than;
sub delete_files_older_than_recursive;

# You should only need to change these if mysqldump complains about something
my @mysqldump_options = qw(
--events
--triggers
--routines
--add-drop-table
--add-drop-database
--add-locks
--comments
--delayed-insert
--disable-keys
--extended-insert
--quick
--quote-names
--default-character-set=utf8
);
# Add any database names you don't want backed up to here
my @mysql_skip_databases = qw(
    information_schema
    mysql
    performance_schema
);

my (@databases) = ();                                      # empty array
my %attr = ( PrintError => 1, RaiseError => 1 );           # Verbose errors from MySQL
#my $host = hostname;                                     # used for saving to output file
my @alist = split(/\./, hostname) ;
my $host = $alist[0];

#my $PROG = basename $0;

my $mysqldump_args = join ' ' => @mysqldump_options;       # combine options to be able to append to mysqldump later on

#####  main  #####
if ($^O ne 'linux') {
        print "[$0]: This runs only on Linux.\n";          # check if we're running the scriot on Linux
        exit;
}


@databases   = &mysql_list_databases();                    # get a list of our networks for whitelisting
print "[$0]: found => @databases\n\n";

# clean up old archives > MAX_DAYS
&delete_files_older_than(MAX_DAYS,DESTFOLDER,"mysql_");

# if we found at least one database
if ( scalar @databases > 0 ) {
        foreach my $database (@databases) {

                # set a timestamp value
                my ($timestamp) = &gettime;

                # set a standard filename for this file including salt8 to avoid filename collisions.
                my ($filename) = DESTFOLDER . "/" . "mysql" . "_" . "$host" . "_" . $database . "_" . $timestamp . "_" . &salt8  .  ".sql";

                # print on screen so we know what's going on
                print "[$0]: backing up $database to $filename\n";

                # dump DB
                &mysql_dump("$database","$filename");
        }
}
##### /main  #####


#####################
####  FUNCTIONS  ####
#####################
# generate ransom string for output file to avoid filename colisions.
#sub generate_random_string {
#    my $res = '';
#    $res.= chr int rand(26)+96 for 1..8;
#    return $res;
#}
sub salt8 {
        my $salt = join '', ('a'..'z')[rand 26,rand 26,rand 26,rand 26,rand 26,rand 26,rand 26,rand 26];
        return($salt);
}

# get all databases - exceptions
sub mysql_list_databases {
        my (@temp) = ();
        my ($entry)='';

        my $dsn = sprintf("DBI:mysql:host=%s;mysql_connect_timeout=30",MYSQLHOST);
        my $dbh;

        if (!($dbh = DBI->connect($dsn, USER, PWD, \%attr)))
        {
             print ("$0: [ERROR] Couldn't connect to DB\n\n");
             exit;
        }

        my $query = sprintf("SHOW DATABASES");
        my $sth = $dbh->prepare($query);
        my $count = $sth->execute();

        while (my $ref = $sth->fetchrow_hashref()) {
              next unless $ref->{Database};
              my $entry = $ref->{'Database'};
              next if grep { $_ eq $entry } @mysql_skip_databases;  # skip databases in our list
              next if ($entry eq '');

              push(@temp,$entry);
        }

        $sth->finish();
        $dbh->disconnect;
        return (@temp);
}

sub mysql_dump {
        my ($db,$dumpfile) = @_;

        umask 077;

        my $tmp = tmpnam();                                    # temp file name

        if(!(-d DESTFOLDER))
        {
                mkdir(DESTFOLDER) or die("unable to create backup dir: $!");  # create backup folder if it does not exist
        }


        if ( -e $tmp ) {
                unless ( unlink $tmp ) {
                        print "[$0]: Can't delete $tmp: $!\n";
                        next;
                }
        }

        #system ("/usr/bin/mysqldump", $mysqldump_args,"-u ", USER,"-p",PWD,$db,"-r ",$tmp);
        my $command = sprintf ("%s %s -u %s -p'%s' %s -r %s",MYSQLDUMP,$mysqldump_args,USER,PWD,$db,$tmp);
        #print "$command\n";

        # execute mysqldump
        system($command);

        # compress mysqldump
        my $tmpcompressed = "$tmp" . ".gz";
        print "[$0]: compressing $tmp to $tmpcompressed\n";
        system("gzip -f $tmp");
        $dumpfile .= ".gz";

        # move update log to backup for later restore if needed
        print "[$0]: moving $tmpcompressed to $dumpfile\n";
        move $tmpcompressed, $dumpfile if -e $tmpcompressed;
        print "\n";
}


sub gettime {
        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
        $year = 1900 + $year;
        my $monn = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")[$mon];
        my $wdayn = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")[$wday];
        my $filename = $year . "_" . $monn . "_" . sprintf("%02d",$mday) . "_" . $wdayn . "_" . $hour . "_" . $min . "_" . $sec;
        return $filename;
}

# recursively create a folder
sub rmkdir{
  my($tpath) = @_;
  my($accum);

  foreach my $mydir (split(/\//, $tpath)){
    $accum = "$accum" . "$mydir/";
    if($mydir ne ""){
      if(! -d "$accum"){
        mkdir $accum;
        chmod(0700, $accum)
      }
    }
  }
}

# delete files matching pattern non-recursively
sub delete_files_older_than() {
        my ($maxdays,$folder,$match) = @_;

        if (! -d $folder) {
                die ("[$0]: folder $folder does not exist: $!");
        }

        opendir (DIR, $folder);
        my @dir = grep { /^$match/ } readdir(DIR);
        closedir(DIR);

        # sort by modification time not really needed
        #@dir = sort { -M "$dir/$a" <=> -M "$dir/$b" } (@dir);

        # do we have at least one item in array ?
        if (scalar(@dir) >0 ) {
                foreach my $file (@dir) {
                        my $full_path = "$folder/$file";
                        # we only care about files ignoring folders
                        next if (!(-f "$full_path"));

                        # return time diff
                        my $diff = -M "$full_path";

                        if ( $diff >= $maxdays ) {
                                # print file to be deleted
                                print "[$0]: Deleting " . $full_path . "\n";
                                unlink ("$full_path");
                        }
                }
        }
}

# delete files matching pattern RECURSIVELY
sub delete_files_older_than_recursive() {
        my ($max_days,$folder,$match) = @_;
        my @file_list;
        use File::Find;

        find ( sub {
                 my $file = $File::Find::name;
                 if ( -f $file ) {
                           push (@file_list, $file);
                 }
        }, $folder);

        @file_list = grep {-f && /$match/} @file_list;

        # do we have at least one item in array ?
        if (scalar(@file_list) > 0 ) {
                my @remove_files = grep { -M $_ > $max_days } @file_list;
                for my $file (@remove_files) {
                        print "[$0]: Deleting " . $file . "\n";
                        unlink $file;
                }
        }
}

