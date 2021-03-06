#!/usr/bin/perl -w

###############################################################################
#Setup
###############################################################################
use strict;
use File::Path;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use File::Temp;
use CGI;
use CGI::Carp;
use IO::Handle;
use Config::General;
use Cwd;

$| = 1;

my $output_folder = "/var/www/metamorph_grid/";
my $webserver = "http://$ENV{SERVER_NAME}/metamorph_grid/";

if (! -e $output_folder) {
	mkpath($output_folder);
	chmod 0775, $output_folder;
	open OUTPUT, ">$output_folder/index.html" or die "$!";
	print OUTPUT &print_auto_redirection_html();
	close OUTPUT;
}

###############################################################################
#Main
###############################################################################

my $q = CGI->new();

print $q->header,                    # create the HTTP header
	  $q->start_html(-title=>'Metamorph Grid File Creator'), # start the HTML
	  $q->h1('Metamorph Grid File Creator');         # level 1 header

print $q->start_form(-method=>"POST",
                 -action=>"webapp.pl",
                 -enctype=>"multipart/form-data");

print $q->h2('Dish Count');
if (defined $q->param('dish_count')) {
    print $q->textfield('dish_count',$q->param('dish_count'),10,10);
} else {
    print $q->textfield('dish_count','',10,10);
}

print $q->h2('Stage Position File (optional)'),
      $q->filefield('uploaded_file','',50,80);

#print $q->h2('Settings');
#
#print $q->h3('Starting X/Y Positions'),
#      $q->textfield('start_x','-1600',10,10),
#      $q->textfield('start_y','-1600',10,10);
#
#print $q->h3('Grid Size'),
#      $q->textfield('grid_size',5);
#
#print $q->h3('Move Increment'),
#      $q->textfield('move_increment',800);
#
print $q->p,
      $q->submit(-name=>"Submit");

print $q->end_form;

my $lightweight_fh = $q->upload('uploaded_file');
# undef may be returned if it's not a valid file handle
if (defined $lightweight_fh) {
    
	# Upgrade the handle to one compatible with IO::Handle:
    my $io_handle = $lightweight_fh->handle();
    $q->param('uploaded_file') =~ /(.*)/;
    
	mkpath(catdir($output_folder,'temp_files'));
    my ($output_handle, $output_file) = File::Temp::tempfile(DIR=>catdir($output_folder,'temp_files')) or die $!;
    
    my $buffer;
    while (my $bytesread = $io_handle->read($buffer,1024)) {
        print $output_handle $buffer or die;
    }
    close $output_handle;
    chmod 0666, "$output_file" or die "$!";
    
    my $dish_count = $q->param('dish_count');

    system("./make_metamorph_grid_file.pl -output_prefix '$output_folder' -dish_count $dish_count -corners $output_file");
    
    print $q->p;
    print "<a href=$webserver/final_stage_positions.STG>Click here to download the complete file.</a>";

} elsif (defined $q->param('dish_count')) {
    my $dish_count = $q->param('dish_count');
 	
    system("./make_metamorph_grid_file.pl -output_prefix '$output_folder' -dish_count $dish_count");
    
    print $q->p;
    print "<a href=$webserver/stage_corners.STG>Click here to download the unfocused corner file.</a>";
}

&print_out_instructions();

print $q->end_html;                  # end the HTML

###############################################################################
#Functions
###############################################################################

sub print_out_instructions {
    print $q->hr;

    print $q->h1('Instructions');

    print "This simple web application builds a file that can be loaded into the
    version of metamorph that comes with the Vivaview microscope to produce a simple
    grid of positions to visit in multiple dishes. In general, a user will want to follow this set of instructions:";

    print $q->ol(
        $q->li("Produce a grid file from scratch, this can be done by clicking the submit button above without specifying the grid file above"),
        $q->li("Load the provided file into metamorph, set the desired focus on each corner in the provided and export the stage position list"),
        $q->li("Back on this website, browse to the exported stage position list file with the above \"Browse...\" button and then click submit again"),
    );

    print "Make sure that the number in the dish count box is always correct when clicking submit.";

    print $q->h2('Dish Count');

    print "The number of dishes in the experiment. The first dish will be in position 1, so if you want to run a 4 dish experiment, make sure that positions 1-4 are filled in the microscope.";
}

sub print_auto_redirection_html {
	return "<!DOCTYPE html>
	<html>
	<head>
	<meta http-equiv=\"Refresh\" content=\"0;url=http://$ENV{SERVER_NAME}/cgi-bin/metamorph_grid/webapp.pl\" />
	</head>

	<body>
	</body>
	</html>";

}
