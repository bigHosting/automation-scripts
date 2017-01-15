#!/usr/bin/perl

# (c) Security Guy 2015-10-09

BEGIN {

        # prefer using module NetAddr::IP if available, otherwise fall back to Net::IP

        if (eval { require NetAddr::IP }) {
                $net_module_name = 'NetAddr::IP';
        } elsif (eval { require Net::IP }) {
                $net_module_name = 'Net::IP';
        } else {
                die ("Either NetAddr::IP or Net::IP module must exist !");
        }
}

if ($#ARGV != 0) {
        print "usage: $0 <network/cidr>\n\n";
        exit;
}

print "\n";

if ( defined $net_module_name && $net_module_name eq 'NetAddr::IP')
{
        #use NetAddr::IP;
        print "\nCisco Wildcard: ";
        print join(' ', NetAddr::IP->new($ARGV[0])->wildcard());

        print "\nNetmask: ";
        print join(' ', NetAddr::IP->new($ARGV[0])->mask());

        print "\nCIDR: ";
        print join(' ', NetAddr::IP->new($ARGV[0])->cidr());
        my $cidr = join(' ', NetAddr::IP->new($ARGV[0])->cidr());

        print "\n\nRange (network && broadcast): ";
        print join(' ', NetAddr::IP->new($ARGV[0])->range());

        #print "\nPrefix: ";
        #print join(' ', NetAddr::IP->new($ARGV[0])->prefix());

        print "\nFirst usable and Last usable: ";
        print NetAddr::IP->new($ARGV[0])->first();
        print " - ";
        print NetAddr::IP->new($ARGV[0])->last();
        print "\n\n";
}

if ( defined $net_module_name && $net_module_name eq 'Net::IP')
{
        # match cidr format
        if( $ARGV[0]=~m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$| )
        {

                #use Net::IP;

                my $ip = new Net::IP ($ARGV[0]) or die (Net::IP::Error());

                print ("IP  : ".$ip->ip()."\n");
                print ("Sho : ".$ip->short()."\n");
                #print ("Bin : ".$ip->binip()."\n");
                print ("Int : ".$ip->intip()."\n");
                print ("Mask: ".$ip->mask()."\n");
                print ("Last: ".$ip->last_ip()."\n");
                print ("Len : ".$ip->prefixlen()."\n");
                print ("Size: ".$ip->size()."\n");
                print ("Type: ".$ip->iptype()."\n");
                #print ("Rev:  ".$ip->reverse_ip()."\n");

                print "\n";
        }
}

