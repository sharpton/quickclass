#!/usr/bin/perl -w

use strict;

my $db_path = "/netapp/home/sharpton/projects/mouse_microbiome/lastdb/prelim/";
my $script  = "/netapp/home/sharpton/projects/mouse_microbiome/scripts/job_launcher.pl";

my @files = glob( "${db_path}*.fa" );
foreach my $file( @files ){
    next unless -e $file;
    print( "perl $script --opt2 ${file}.db\n" );
    `perl $script --opt2 ${file}.db`;
    sleep( 300 );
}
