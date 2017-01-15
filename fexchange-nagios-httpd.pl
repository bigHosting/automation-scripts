#!/usr/bin/perl
# {{ ansible_managed }}

use strict;
use warnings;
use File::stat;

#############
# VARIABLES #
#############
my $file_to_monitor = "/var/log/httpd/error-fexchange.log";
my %settings;
my %ERRORS = ('UNKNOWN' , '3',
              'OK' , '0',
              'WARNING', '1',
              'CRITICAL', '2');
my $state='UNKNOWN';
$settings{'timeout'} = 15;
$settings{'threshold'} = 0;

$SIG{'ALRM'} = sub {
     print ("ERROR: Server Timeout (alarm)\n");
     $state = "WARNING";
     exit $ERRORS{$state};
};
alarm($settings{'timeout'});

if ( -f $file_to_monitor)
{
        my $size = stat($file_to_monitor)->size;
        if ( $size > $settings{'threshold'} ) 
        {
             $state = "CRITICAL";
             print $state . ": size of $file_to_monitor > $settings{'threshold'} " . "\n";
        } else {
             # happy to say that links are in perfect shape
             $state = "OK";
             print $state . "\n";
        }
} else 
{
        # file does not exist
        $state = "UNKNOWN";
        print $state . "\n";
}

exit $ERRORS{$state};
