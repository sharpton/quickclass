#!/usr/bin/perl -w

use strict;
use Getopt::Long;

my ($input, $output, $sample, $phenotype);
GetOptions(
    "i=s" => \$input,
    "o=s" => \$output,
    "s=s" => \$sample,
    "p=s" => \$phenotype,
    );

open( IN, $input ) || die "Can't open $input for read: $!\n";
open( OUT, ">$output" ) || die;
my $taxa  = {};
my $total = 0;

while( <IN> ){
    $total++;
    if( $_ =~ m/Firmicutes/ ){
	$taxa->{"Firmicutes"}++;
    }
    if( $_ =~ m/Bacteroidetes/ ){
	$taxa->{"Bacteroidetes"}++;
    }
}

foreach my $taxon( keys( % { $taxa } ) ){
    my $counts = $taxa->{$taxon};
    my $ratio  = $counts / $total;
    print OUT join( "\t", $sample, $taxon, $counts, $total, $ratio, $phenotype, "\n" );
}
close IN;
close OUT;
