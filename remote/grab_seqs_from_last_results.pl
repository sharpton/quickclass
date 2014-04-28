#!/usr/bin/perl -w

use strict;
use Bio::SeqIO;
use Getopt::Long;

my( $input, $output, $seqpath );
GetOptions(
    "i=s" => \$input,
    "o=s" => \$output,
    "s=s" => \$seqpath,
    );

open( IN, $input ) || die "Can't open $input for read: $!\n";
my $seqin  = Bio::SeqIO->new( -file => "zcat $seqpath |", -format => "fastq" );
my $seqout = Bio::SeqIO->new( -file => ">$output", -format => "fasta" );

my $hits = {};
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
	$hits->{$qid}++;
    } else {
	warn( "couldn't parse results from line:\n$_ ");
	next;
    }
}
close IN;

while( my $seq = $seqin->next_seq() ){
    my $id = $seq->display_id();
    if( defined( $hits->{$id} ) ){
	$seqout->write_seq( $seq )
    }
}

