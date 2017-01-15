#!/usr/bin/perl

use strict;
use warnings;

use POSIX;
use File::Copy; # required for move function

#####################
# declare functions #
#####################
sub delete_files_older_than;


##################
#####  MAIN  #####
##################

my $upload      = "/var/www/SITES/fileshare.upload";           # where files are automatically uploaded
my $maxdays     = 80;                                      # keep the logs for X amount of days


if ( ! -d $upload) {
   print "$0: folder $upload does not exist: $!";
   exit(1);
}


opendir (DIR, $upload);
my @dir = readdir(DIR);
closedir(DIR);


        # do we have at least one item in array ?
        if (scalar(@dir) >0 ) {
                foreach my $file (@dir) {
                        my $full_path = "$upload/$file";

                        # skip . and '..'
                        next if ($file =~ m/^\./);

                        next if ($full_path =~ /.htaccess/);

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

