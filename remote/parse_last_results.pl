#!/usr/bin/perl -w

use strict;
use Getopt::Long;

my( $input, $output, $sample, $phenotype );
GetOptions(
    "i=s" => \$input,
    "o=s" => \$output,
    "s=s" => \$sample,
    "p=s" => \$phenotype,
    );
die if( !defined( $sample ) || !defined( $phenotype ) );

open( IN, $input ) || die "Can't open $input for read: $!\n";
open( OUT, ">$output" ) || die "Can't open $output for write: $!\n";

my $hitcounts = {};
while( <IN> ){
    chomp $_;
    next if( $_ =~ m/^#/ );
    if($_ =~ m/^(.*?)\s+(.*?)\s+(.*?)\s+(.*?)\s+(.*?)\s+(.*?)\s+(.*?)\s+(.*?)\s+(.*?)\s+(.*?)\s+(.*?)\s+(.*?)$/ ){
	my $score  = $1;
	my $tid    = $2;
	my $qid    = $7;
	my $start  = $8;
	my $stop   = $start + $9;
	my $qlen   = $11;
	my $ko;
	if( $tid =~ m/^(K.*?)\-/ ){
	    $ko = $1;
	} else{
	    warn ("Can't get $ko from $tid\n" );
	    next;
	}	
	#fuzzy clustering: a read can belong to multiple families here.
	#also, since reads are so short, we'll assume that it's rare that it hits same fam > 1 time
	$hitcounts->{$ko}++;
    } else {
	warn( "couldn't parse results from line:\n$_ ");
	next;
    }
}
close IN;

foreach my $hit( keys( %{ $hitcounts } ) ){
    my $count = $hitcounts->{$hit};
    print OUT join( "\t", $hit, $count, $sample, $phenotype, "\n" );
}
close OUT;
