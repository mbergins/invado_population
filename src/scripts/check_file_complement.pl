#!/usr/bin/env perl

################################################################################
# Global Variables and Modules
################################################################################

use lib "../lib";
use lib "../lib/perl";

use strict;
use File::Find;
use File::Path;
use File::Spec::Functions;
use File::Basename;
use File::Copy;
use Getopt::Long;
use Data::Dumper;

use Config::ImageSet qw(ParseConfig);

#Perl built-in variable that controls buffering print output, 1 turns off
#buffering
$| = 1;

my %opt;
$opt{debug} = 0;
GetOptions(\%opt, "cfg|c=s", "debug|d", "lsf|l")
  or die;

die "Can't find cfg file specified on the command line" if not exists $opt{cfg};

print "Gathering Config\n" if $opt{debug};
my %cfg = ParseConfig(\%opt);

################################################################################
# Main Program
################################################################################

my @folders = sort <$cfg{individual_results_folder}/*>;

die "Unable to find image results folders" if scalar(@folders) == 0;

our @file_list;
find(\&collect_all, ($folders[0]));

my @first_file_set = @file_list;
my $first_file_count = scalar(@file_list);
foreach (@folders) {
    @file_list = ();
    find(\&collect_all, ($_));
	
	if (scalar(@file_list) != $first_file_count) {
		my $die_str = "\nProblem with Directory: $_\nFound " . scalar(@file_list) . " files in set, while $first_file_count in the first directory.\n\n";
		die $die_str;
	};
}

################################################################################
# Functions
################################################################################

sub collect_all {
	if (not($_ =~ /^\./)) {
    	push @file_list, $File::Find::name;
	} 
}
