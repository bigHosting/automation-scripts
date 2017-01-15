#!/usr/bin/perl

use strict;
use Socket qw( inet_aton );

# http://cpansearch.perl.org/src/MANU/Net-IP-1.26/IP.pm
# Definition of the Ranges for IPv4 IPs
my %IPv4ranges = (
    '00000000'                         => 'PRIVATE',     # 0/8
    '00001010'                         => 'PRIVATE',     # 10/8
    '0110010001'                       => 'SHARED',      # 100.64/10
    '01111111'                         => 'LOOPBACK',    # 127.0/8
    '1010100111111110'                 => 'LINK-LOCAL',  # 169.254/16
    '101011000001'                     => 'PRIVATE',     # 172.16/12
    '110000000000000000000000'         => 'RESERVED',    # 192.0.0/24
    '110000000000000000000010'         => 'TEST-NET',    # 192.0.2/24
    '110000000101100001100011'         => '6TO4-RELAY',  # 192.88.99.0/24
    '1100000010101000'                 => 'PRIVATE',     # 192.168/16
    '110001100001001'                  => 'RESERVED',    # 198.18/15
    '110001100011001101100100'         => 'TEST-NET',    # 198.51.100/24
    '110010110000000001110001'         => 'TEST-NET',    # 203.0.113/24
    '1110'                             => 'MULTICAST',   # 224/4
    '1111'                             => 'RESERVED',    # 240/4
    '11111111111111111111111111111111' => 'BROADCAST',   # 255.255.255.255/32
);

my $ERRNO;
my $ERROR;

# http://cpansearch.perl.org/src/MANU/Net-IP-1.26/IP.pm
#------------------------------------------------------------------------------
# Subroutine ip_iptypev4
# Purpose           : Return the type of an IP (Public, Private, Reserved)
# Params            : IP to test, IP version
# Returns           : type or undef (invalid)
sub ip_iptypev4 {
    my ($ip) = @_;

    # check ip
    if ($ip !~ m/^[01]{1,32}$/) {
        $ERROR = "$ip is not a binary IPv4 address $ip";
        $ERRNO = 180;
        return;
    }

    # see if IP is listed
    foreach (sort { length($b) <=> length($a) } keys %IPv4ranges) {
        return ($IPv4ranges{$_}) if ($ip =~ m/^$_/);
    }

    # not listed means IP is public
    return 'PUBLIC';
}

# http://cpansearch.perl.org/src/MANU/Net-IP-1.26/IP.pm
#------------------------------------------------------------------------------
# Subroutine ip_iptobin
# Purpose           : Transform an IP address into a bit string
# Params            : IP address, IP version
# Returns           : bit string on success, undef otherwise
sub ip_iptobin {
    my ($ip, $ipversion) = @_;

    # v4 -> return 32-bit array
    if ($ipversion == 4) {
        return unpack('B32', pack('C4C4C4C4', split(/\./, $ip)));
    }

    # Strip ':'
    $ip =~ s/://g;

    # Check size
    #unless (length($ip) == 32) {
    #    die ("Bad IP address $ip");
    #    $ERRNO = 102;
    #    return;
    #}

    # v6 -> return 128-bit array
    return unpack('B128', pack('H32', $ip));
}

sub ip2long($)
{
	return( unpack( 'N', inet_aton(shift) ) );
}

sub in_subnet($$)
{
	my $ip = shift;
	my $subnet = shift;

	my $ip_long = ip2long( $ip );

	if( $subnet=~m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$| )
	{
		my $subnet = ip2long( $1 );
		my $mask = ip2long( $2 );

		if( ($ip_long & $mask)==$subnet )
		{
			return( 1 );
		}
	}
	elsif( $subnet=~m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$| )
	{
		my $subnet = ip2long( $1 );
		my $bits = $2;
		my $mask = -1<<(32-$bits);

		$subnet&= $mask;

		if( ($ip_long & $mask)==$subnet )
		{
			return( 1 );
		}
	}
	elsif( $subnet=~m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.)(\d{1,3})-(\d{1,3})$| )
	{
		my $start_ip = ip2long( $1.$2 );
		my $end_ip = ip2long( $1.$3 );

		if( $start_ip<=$ip_long and $end_ip>=$ip_long )
		{
			return( 1 );
		}
	}
	elsif( $subnet=~m|^[\d\*]{1,3}\.[\d\*]{1,3}\.[\d\*]{1,3}\.[\d\*]{1,3}$| )
	{
		my $search_string = $subnet;

		$search_string=~s/\./\\\./g;
		$search_string=~s/\*/\.\*/g;

		if( $ip=~/^$search_string$/ )
		{
			return( 1 );
		}
	}

	return( 0 );
}


unless (@ARGV == 2)
{
     print "Usage: $0 <IP> <CIDR>\n";
     exit;
}

#####  main  #####
my $ip = $ARGV[0];
my $cidr = $ARGV[1];

die "$[0]: not an IP" if ( $ip !~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/ );

my $type = &ip_iptypev4 ( &ip_iptobin ( $ip, 4 ) );

if(in_subnet($ip, $cidr )){

        print "[$0]: $type IP $ip matches $cidr\n";
        exit(0);

} else {

        print "[$0]: $type IP $ip does NOT match $cidr\n";
        exit(1);

}

exit(1);
##### /main  #####



