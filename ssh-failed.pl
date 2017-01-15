#!/usr/bin/perl

#
# (c) Security Guy
#

BEGIN {
    use constant VERSION    => "0.3";
    use constant RELDATE    => "2013.08.01";
    use constant BY         => "Security Team";
}

use strict;
use warnings;
use POSIX qw(strftime);
use Getopt::Long;

my (%options,$user,%count,$bounce);
my $minimum_failed='40';

my %bounces = (
  "b1" => "/localservices/logs/hosts/b1/",
  "b2" => "/localservices/logs/hosts/b2/",
  "b3" => "/localservices/logs/hosts/b3/",
  "b4" => "/localservices/logs/hosts/b4/",
  "b5" => "/localservices/logs/hosts/b5/",
  "b6" => "/localservices/logs/hosts/b6/",
  "b7" => "/localservices/logs/hosts/b7/",
  "b8" => "/localservices/logs/hosts/b8/"
);


GetOptions( \%options,
        'b|bounce=s' => \$bounce,
        'h|help'    => \&display_help,
        'v|version' => sub{ print "This is $0, version " .VERSION. "\n"; exit; }
) or &display_help;
&display_help if (scalar(@ARGV < 0));
&display_help if (!defined($bounce));

my $full_path = $bounces {lc $bounce}.strftime "%Y/%m/%d/authpriv/authpriv_%Y_%m_%d.log",localtime ;
#print "\nLooking for failed logins in '$full_path'\n\n";

my @files = glob("$full_path");
foreach my $file (@files) {
        if ( -f $file ) {
                open(LOG,$file);
                foreach my $line (<LOG>) {
                  chomp($line);
                  if ( ($line =~ m/authentication failure/) && ($line =~ m/sshd:auth/) && ($line =~ /user=([^ ]+)/) ) {
                      $user=$1;
                      $count{"$user"}++;
                  }

                }
                close(LOG);
        }
}

foreach my $key (sort { $count{$b} <=> $count{$a} } keys %count) {
        print "$key ("  . $count{"$key"} . "), " if ($count{"$key"} > $minimum_failed);
}


sub display_help {
    print "
Get ssh login failures from bounce boxes
usage: $0 -b|--bounce=b2  [-h|--help] [-v|--version]
       $0 -b b2       ==> get stats from b2 bounce box
\n";
exit 0;
}

