#!/usr/bin/perl

#
# (c) SecurityGuy  2015.07.06
#

use strict;
use warnings;

#INIT {
#        open  *{0} or die "What!? $0:$!";
#        flock *{0}, LOCK_EX|LOCK_NB or die "[*] $0: is already running!n";
#}

sub rmkdir;
sub delete_files_older_than;
sub delete_files_older_than_recursive;
sub subdirs;
sub gzip_me;

##################
#####  MAIN  #####
##################
my $storage       = "/localservices/logs/hosts";            # where files are automatically created
my $days          = 90;                                     # keep the logs for X amount of days
my $days_gzip     = 3;                                      # compress files that have mod time > 2 days

if ( ! -d $storage) {
   print "$0: ERR: folder $storage does not exist: $!";
   exit(1);
}

# too may levels for subforders, we need to break them down for faster access to shared FS
my @subfolders  = &subdirs ($storage);
if ( scalar ( @subfolders ) < 1 )
{
        print "[*] $0: ERR: no subfolders found in $storage!";
        exit (1);
}

foreach my $sub ( @subfolders )
{
        # remove files older than XX days
        &delete_files_older_than_recursive($days,$sub);

        # gzip files older than $days_gzip days that do not match file endining in gz
        &gzip_me($days_gzip,$sub,"gz");
}

exit (0);
######################
#####  END MAIN  #####
######################

#####################
# declare functions #
#####################

# get subfolders non-recursive
sub subdirs {
    my $dir = shift;
    my $DIR;
    my (@alldirs) = ();
    # I use variable file handles so function can be reentrant
    opendir $DIR, $dir or die "opendir $dir - $!";
    my @entries = readdir $DIR;

    # Get only directories from dir listing.
    my @subdirs = grep { -d "$dir/$_" } @entries;

    # Remove "hidden" directories (including . and ..) from that list.
    @subdirs = grep { !/^\./ } @subdirs;

    for my $subdir ( @subdirs ) {
        push(@alldirs, "$dir/$subdir");
        print "[*] $0: INFO: add subfolder $dir/$subdir\n";
    }
    closedir $DIR;
    return (@alldirs);
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
sub delete_files_older_than {
        my ($maxdays,$folder) = @_;

        if (! -d $folder) {
                die ("[$0]: folder $folder does not exist: $!");
        }

        opendir (DIR, $folder);
        my @dir = readdir(DIR);
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
                                print "[*] $0: Deleting " . $full_path . "\n";
                                unlink ("$full_path");
                        }
                }
        }
}

# delete files matching pattern RECURSIVELY
sub delete_files_older_than_recursive {
        my ($max_days,$folder) = @_;
        my @file_list;

        print "[*] $0: INFO: parsing folder $folder\n";
        use File::Find;

        find ( sub {
                 my $file = $File::Find::name;
                 if ( -f $file ) {
                           push (@file_list, $file);
                 }
        }, $folder);

        #@file_list = grep {-f && /$match/} @file_list;

        # do we have at least one item in array ?
        if (scalar(@file_list) > 0 ) {
                my @remove_files = grep { -M $_ > $max_days } @file_list;
                for my $file (@remove_files) {
                        print "[*] $0: INFO: Deleting " . $file . "\n";
                        unlink $file;
                }
        }
}

# gzip files matching pattern RECURSIVELY
sub gzip_me {
        my ($max_days,$folder,$pattern) = @_;
        my @file_list;

        print "[*] $0: INFO: compressing files in folder $folder\n";
        use File::Find;

        find ( sub {
                 my $file = $File::Find::name;
                 if ( -f $file ) {
                           push (@file_list, $file);
                 }
        }, $folder);

        @file_list = grep {-f && /$pattern/} @file_list;

        # do we have at least one item in array ?
        if (scalar(@file_list) > 0 ) {
                my @compress_files = grep { -M $_ > $max_days } @file_list;
                for my $file (@compress_files) {
                        print "[*]: $0 Compressing " . $file . "\n";
                        system ("/bin/gzip $file > /dev/null 2>&1");
                }
        }
}

