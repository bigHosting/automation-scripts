#!/usr/bin/perl

# (C) Security Guy 2015.09.18

# flush buffers after every write
$| = 1;

use strict;
use warnings;

#use POSIX qw(strftime);      # time options
use IO::Socket;               # socket to communicate w remote server
use File::Basename;           # for basename
use Sys::Hostname;            # for sending source host to graylog
use POSIX qw(strftime);       # time options
use File::Tail;               # for tailing files, needs perl-File-Tail & perl-Time-HiRes


my %settings = (
        graylog_server       => 'X.Y.90.71',
        graylog_port         => '12218',
);
$settings{'source'} = hostname;

my $full_path = "/var/log/messages";
if ( ! -f $full_path ) {
        print "[*] $0: ERROR: $full_path does not exist or not a file\n";
        exit(1);
}

# The number of seconds to wait until re-execing ourselves
my $stime = 86400;

# When did we exec last?
my $lasts = time();

# Process the logs
while (1)
{
        # Shall we exec ourselves? Perl memory management, eh? ;)
        if ( (time() - $lasts) > $stime )
        {
                print ("Reincarnating...\n");
                exec("/localservices/sbin/graylog-sshd.pl");
        }



        my $file = File::Tail->new(name => $full_path, interval=>1);
        while (defined(my $line= $file->read)) {

                next if ( $line !~ m/sshd/ );
                next if ( $line !~ m/illegal user/);
                my $message = '';
                my $send = 0;


                # Sep 18 14:24:17 shell1c0 sshd[22724]: Failed password for illegal user admin from 89.248.172.166 port 46589 ssh2
                if ( $line =~ m/Failed password for illegal user/)
                {
                        $send = 1;

                        my ($user,$sourceip) = ($line =~ m{(?:.*)(?:sshd)(?:.*)(?:user\s+)(.*)(?:from)(.*)(?:port.*)});
                        my $timestamp = strftime "%F %T", (localtime(time()) );

                        $message = "{ \"version\": \"1.1\", \"host\": \"$settings{'source'}\", \"short_message\": \"SHELL\", \"hService\": \"SSHD\", \"timestamp\": \"$timestamp\", \"SourceIP\": \"$sourceip\", \"User\": \"$user\" }";
                        print $message . "\n";
                }


                if ($send)
                {
                        # open udp socket
                        my $client = new IO::Socket::INET(
                                        PeerAddr => $settings{"graylog_server"},
                                        PeerPort => $settings{"graylog_port"},
                                        Timeout  => 5,
                                        Proto    => 'udp',
                       );

                       $client->send($message);
                       # terminate the connection when we're done
                       close($client);
                }


        }
}


