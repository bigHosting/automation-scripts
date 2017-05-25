#!/usr/bin/perl

#
# (c) SecurityGuy 2017.05.24
#
# Use F5 API to count the number of 'chains' and number of entries in a chain
#
#
# tested on F5 BIGIP 11.5.4 , 11.6.1
#    get the policy names:
#        curl -sk -u user:password -H "Content-Type: application/json" -X GET https://lb1.domain.com/mgmt/tm/security/firewall/policy/ | jq '.'
#    get the list of 'chains' in a policy
#        curl -sk -u user:password -H "Content-Type: application/json" -X GET https://lb1.domain.com/mgmt/tm/security/firewall/policy/~Common~hsec-AFM/rules | jq '.'
#    get the individual rules
#        curl -sk -u user:password -H "Content-Type: application/json" -X GET https://lb1.domain.com/mgmt/tm/security/firewall/rule-list/~Common~hSec_PROD_WEB_REALS/rules| jq '.'


use warnings;
use strict;

use LWP::UserAgent;
use JSON qw( decode_json encode_json from_json);
#use Data::Dumper;



sub api ($)
{
        my $link = shift;
        # you need the user:password encoded in base64 in the Authorization field
        my @headers = (
            'Content-Type'   => 'application/json',
            'Authorization'  => 'Basic abcd******',
            'user-agent'     => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.2.10) Gecko/20100914 Firefox/3.6.10' 
        );

        my $ua = new LWP::UserAgent;
        $ua->ssl_opts( verify_hostname => 0   );
        $ua->ssl_opts( SSL_verify_mode => 0x0 );
        $ua->env_proxy();

        my $request = HTTP::Request->new( 'GET', $link );
        $request->header( @headers );
        my $result = $ua->request($request);


        # is request getting 200 ?
        if (!$result->is_success)
        {
                die "[*] $0 ERROR: remote page dif not return http code 200: -> " . $result->status_line; 
        }

        my $decoded_json = decode_json($result->content);


        my @data = @{ $decoded_json->{'items'} };
        return (@data);
}

unless (@ARGV == 1)
{
     print "\nUsage: $0 <lb>\n";
     print "$0 lb1.domain.com\n\n";
     exit;
}

my $counter_chains = 0;
my $counter_rules  = 0;

my $target = $ARGV[0];
my $target_policies = "https://$target/mgmt/tm/security/firewall/policy/";

# get all policies
my @policies = &api($target_policies);

foreach my $policy (@policies)
{
        my $policy_name = $policy->{name};
        # We know that our policy name has 'AFM' in the name
        next if ($policy_name !~ /AFM/i);

        # the path to the policy
        my $policy_path = $policy->{fullPath};
        $policy_path =~ s#/#~#g;
        my $policy_url = "https://$target/mgmt/tm/security/firewall/policy/$policy_path/rules";
        my @chains = &api($policy_url);

        foreach my $chain (@chains)
        {
                my $link = $chain->{ruleList};
                $link =~ s#/#~#g;
                my $details = sprintf ("https://$target/mgmt/tm/security/firewall/rule-list/%s/rules",$link );
                print $details . "\n";
                my $num = scalar (&api($details));
                $counter_rules += $num;
                $counter_chains++;
        }
}

print $target . ", CHAINS " . $counter_chains . ", RULES " . $counter_rules . "\n";

