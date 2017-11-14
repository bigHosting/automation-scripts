#!/usr/local/bin/perl

use 5.014;
use warnings;
use strict;

use Socket;
#use Data::Dumper;


sub resolve_dns ($)
{
        my $name = shift;
        my %hash;

        my @addresses_ipv4 = ();
        my @addresses_ipv6 = ();
        my $err;

        # IPV4
        @addresses_ipv4 = gethostbyname($name);
        if ( @addresses_ipv4 )
        {
                @addresses_ipv4 = map { inet_ntoa($_) } @addresses_ipv4[4 .. $#addresses_ipv4];
                foreach my $ipv4 (@addresses_ipv4)
                {
                        push @{ $hash{ipv4} }, $ipv4;
                }
        }

        # IPv6
        ( $err, @addresses_ipv6 ) = Socket::getaddrinfo( $name, 0, { 'protocol' => Socket::IPPROTO_TCP, 'family' => Socket::AF_INET6 } );
        if ( not $err )
        {
                foreach my $addr (@addresses_ipv6)
                {
                        my ( $err, $host ) = Socket::getnameinfo( $addr->{addr}, Socket::NI_NUMERICHOST );
                        if ($err) {  next }
                        push @{ $hash{ipv6} }, $host;
                }
        }

        return %hash;
}


my $name = "google.com";
#my $name = "monerohash.com";

my %ips = &resolve_dns($name);
#print Dumper ( \%ips );

if ( scalar ( keys %ips ) > 0 )
{
        # loop through 'ipv4', 'ipv6'
        foreach my $protocol ( keys %ips )
        {
                # loop through each IP
                foreach my $ip ( @{ $ips{$protocol} } )
                {
                        print "$protocol $name $ip\n";
                }
        }
}
