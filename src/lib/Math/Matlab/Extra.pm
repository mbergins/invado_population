#!/usr/bin/env perl

###############################################################################
# Global Variables and Modules
###############################################################################
package Math::Matlab::Extra;

use strict;
use warnings;
use File::Path;
use File::Basename;
use Math::Matlab::Local;
use File::Temp;
use Cwd;

###############################################################################
# Functions
###############################################################################

sub execute_commands {
    my @matlab_code;
    if (ref($_[0]) eq "ARRAY") {
        @matlab_code = @{$_[0]};
    } elsif (ref($_[0]) eq "SCALAR") {
        @matlab_code = ${$_[0]};
    } else {
        die "Expected first argument to execute_commands to be an ref, specifically a scalar or an array ref";
    }
	
	my %opt = %{$_[1]};

    my $matlab_object = Math::Matlab::Local->new();
 	$matlab_object->root_mwd($opt{abs_script_dir});

    unlink($opt{error_file}) if (-e $opt{error_file});

    foreach my $command (@matlab_code) {
        if (not($matlab_object->execute($command))) {
            &File::Path::mkpath(&File::Basename::dirname($opt{error_file}));
            open ERR_OUT, ">>$opt{error_file}" or die "Error in opening Matlab Error file: $opt{error_file}.";
            print ERR_OUT $matlab_object->err_msg;
            print ERR_OUT "\n\nMATLAB COMMANDS\n\n$command";
            close ERR_OUT;
        }
		$matlab_object->remove_files;
    }
}

1;
