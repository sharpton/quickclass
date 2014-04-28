#!/usr/bin/perl -w

use strict;
use Bio::SeqIO;
use File::Basename;

my $ko_file = $ARGV[0];
my $output  = "${ko_file}.mod";

my $ko = basename($ko_file, ".fa");

my $seqs = Bio::SeqIO->new( -file => "$ko_file", -format => "fasta");
my $outseqs = Bio::SeqIO->new( -file => ">$output", -format => "fasta" );
while( my $seq = $seqs->next_seq ){
    my $id = $seq->display_id;
    $id = "${ko}-${id}";
    $seq->display_id( $id );
    $outseqs->write_seq( $seq );
}
