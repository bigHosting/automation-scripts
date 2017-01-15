#!/usr/bin/perl
use strict; use warnings;
 
my @mount_points = do {local @ARGV = '/etc/mtab'; <>};
foreach my $mnt (@mount_points){
    next unless $mnt =~ /nfs/;
    my ($node, $mnt_point, $fs, $options, $dump, $fsck) = split /\s+/, $mnt;
    print "Found NFS share $node mounted on $mnt_point\n";
}
