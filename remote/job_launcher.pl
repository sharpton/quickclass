#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use File::Path ("make_path");
use File::Basename;
use File::Find qw(finddepth);
use Getopt::Long;
use Data::Dumper;
use IPC::System::Simple qw(capture $EXITVAL);

#perl run_seqret_by_week.pl - Submit EMBOSS seqret jobs to convert fastq files to fasta file. 
#built off of run_seqret.pl, which was template wrapper script for the week14 data. This version
#crawls across the by_week temporal metagenomic data and launches array jobs for each subdirectory.

system( "date" );
print( "job_launcher.pl @ARGV\n" );

my ( $one_week, $one_sample );
my $masterdir = "/scrapp2/sharpton/ibdmouse/by_week/";  #common to both source and link dirs
my @samples   = (75, 90, 96, 61, 73, 83, 102, 84, 92 );
#my @weeks     = ( 6, 12 );
my @weeks     = 6;
my $array     = 1;
my $sleep     = 30;  #number of seconds
my $countmax  = 360; #number of loops
my $execute   = 1;  #launch the jobs?
my $test_one  = 0;  #submit a single batch for testing
my $scripts   = "/netapp/home/sharpton/projects/mouse_microbiome/scripts";

my $indir_suffix  = "rdp";
my $outdir_suffix = "taxonomycounts";
my $method        = "taxonomycounts";
my $option1       = 1; 
#my $option2       = "/netapp/home/sharpton/projects/mouse_microbiome/lastdb/prelim/stap_16S_BAC.fa.db";
my $option2       = "/netapp/home/sharpton/projects/mouse_microbiome/lastdb/prelim/All_Morgan_KO.fa.db";
my $dbname        = basename( $option2, ".fa.db" );
my $option3       = "fastq"; #the raw sequences to grab

my %phenotypes = ( 75 => "WT",
		   90 => "WT",
		   96 => "WT",
		   61 => "DNR",
		   73 => "DNR",
		   83 => "DNR",
		   102 => "DNR",
		   84 => "WT",
		   92 => "DNR",
);

#run time options can be used to override the array of values, listed above
GetOptions(
    "w|week:i"   => \$one_week,
    "s|sample:i" => \$one_sample,    
    "m|method:s" => \$method,
    "is|indir:s" => \$indir_suffix, #not a full path!
    "os|outdir:s" => \$outdir_suffix, #not a full path!
    );

if( defined( $one_sample ) ){
    @samples = ( $one_sample );
}
if( defined( $one_week ) ){
    @weeks = ( $one_week );
}

my $qsub;

foreach my $sample( @samples ){
    print $sample . "\n";
    my $phenotype = $phenotypes{$sample};
    foreach my $week( @weeks ){
	my $indir   = "/week${week}/${sample}_${week}/${indir_suffix}/"; #location of input data 
	my $outdir  = "/week${week}/${sample}_${week}/${outdir_suffix}/"; #location of output data
	my $inpath  = "${masterdir}/${indir}";
	my $outpath = "${masterdir}/${outdir}";
	
	make_path( "${outpath}" );

	my @files;
	finddepth(sub {
	    return if($_ eq '.' || $_ eq '..');
	    push @files, $File::Find::name;
		  }, $inpath );

	my $n_files = scalar( @files );
	#ended up not using this since lastal can input fastq
	if( $method eq "seqret" ){
	    print( "qsub -t 1-${n_files} run_seqret_by_week_array.sh $inpath $outpath\n" );
	    if( $execute ){
		system( "qsub -t 1-${n_files} run_seqret_by_week_array.sh $inpath $outpath" );
		sleep( $sleep ); #don't flood the scheduler with jobs.
	    }
	}	
	#ended up not using this since lastal can translate 
	if( $method eq "transeq" ){
	    #doesn't currently split on stops
	    print(  "qsub -t 1-${n_files} run_transeq_by_week_array.sh $inpath $outpath .fa .pep\n" ); 
	    if( $execute){
		system( "qsub -t 1-${n_files} run_transeq_by_week_array.sh $inpath $outpath .fa .pep"); 
	    }
	}
	#ended up running lastdb on the KO groups since to reduce disc space requirements
	if( $method eq "lastdb" ){
	    #option1 is -Q or format, 
	    print(  "qsub -t 1-${n_files} run_lastdb_by_week_array.sh $inpath $outpath .fa .fd.db $option1\n" ); 
	    if( $execute){
		system( "qsub -t 1-${n_files} run_lastdb_by_week_array.sh $inpath $outpath .fa .fd.db $option1"); 
	    }
	}
	if( $method eq "lastal" ){
	    #option1 is -Q or format (e.g., 1) set as 1 for current illumina output
	    #option2 is location of searchdb
	    #option3 is frameshift cost (e.g., 15), doesn't work with Q != 0
	    print(  "qsub -t 1-${n_files} ${scripts}/run_lastal_by_week_array.sh $inpath $outpath .fastq .tab $option1 $option2\n" );
	    if( $execute){
		$qsub = IPC::System::Simple::capture( "qsub -t 1-${n_files} ${scripts}/run_lastal_by_week_array.sh $inpath $outpath .fastq .tab $option1 $option2" );
		warn( $qsub );
		(0 == $EXITVAL) or die( "Error in lastal qsub: $qsub" );
	    }
	}
	#best to run this on interactive node
	#if( $method eq "catresults" ){
	#    print( "cat @files > ${outpath}/${sample}_${week}_$dbname.tab\n" );
	#    if( $execute ){
	#	system( "cat @files > ${outpath}/${sample}_${week}_$dbname.tab" );
	#    }
	#    next;
	#}
	#crude submission script
	if( $method eq "catresults" ){
	    print( "qsub ${scripts}/run_cat_files.sh  ${outpath}/${sample}_${week}_$dbname.tab @files\n" );
	    if( $execute ){
		$qsub = IPC::System::Simple::capture( "qsub ${scripts}/run_cat_files.sh  ${outpath}/${sample}_${week}_$dbname.tab @files" );
		warn( $qsub . "\n" );
	    }
	}	
	if( $method eq "parseresults" ){
	    print( "qsub -t 1-${n_files} ${scripts}/run_parse_last_results.sh $inpath $outpath .tab .tab $dbname ${sample}_${week} $phenotype\n" );
	    if( $execute ){
		$qsub = `qsub -t 1-${n_files} ${scripts}/run_parse_last_results.sh $inpath $outpath .tab .tab $dbname ${sample}_${week} $phenotype 2>&1`;
	    }
	}
	if( $method eq "countreads" ){
	    print( "qsub -t 1-${n_files} ${scripts}/run_count_seqs_in_gz_fastq.sh $inpath $outpath .fastq.gz .count\n" );
	    if( $execute ){
		system( "qsub -t 1-${n_files} ${scripts}/run_count_seqs_in_gz_fastq.sh $inpath $outpath .fastq.gz .count\n" );
	    }
	}
	#best to do on interactive node
	if( $method eq "catcountreads" ){
	    print( "cat @files > ${outpath}/${sample}_${week}_readcounts.tab\n" );
	    if( $execute ){
		system( "cat @files > ${outpath}/${sample}_${week}_readcounts.tab" );
	    }
	}
	if( $method eq "16Sreads" ){
	    my $seqdir  = "/week${week}/${sample}_${week}/${option3}/"; #location of output data
	    my $seqpath  = "${masterdir}/${seqdir}";
	    print( "qsub -t 1-${n_files} run_grab_seqs_from_lastal.sh $inpath $outpath .tab .fa $dbname .fa.db $seqdir .fastq.gz\n" );
	    if( $execute ){
		system( "qsub -t 1-${n_files} run_grab_seqs_from_lastal.sh $inpath $outpath .tab .fa $dbname .fa.db $seqpath .fastq.gz\n" );
	    }
	}
	if( $method eq "rdp" ){
	    print( "qsub -t 1-${n_files} run_rdp_classifier.sh $inpath $outpath .tab .tab\n" );
	    if( $execute ){
		system( "qsub -t 1-${n_files} run_rdp_classifier.sh $inpath $outpath .tab .tab" );
	    }
	}
	if( $method eq "taxonomycounts" ){
	    my $file = $files[0];
	    print( "perl parse_taxonomy.pl -i ${file} -o ${outpath}/taxonomy_counts.tab -s ${sample}_${week} -p $phenotype\n" );
	    if( $execute ){
		system( "perl parse_taxonomy.pl -i ${file} -o ${outpath}/taxonomy_counts.tab -s ${sample}_${week} -p $phenotype" );
	    }
	}
	my $job_id;
	if( $qsub =~ m/Your job (\d+) \(/ ){
	    $job_id = $1;
	} elsif( $qsub =~ m/Your job-array (\d+)\./ ){
	    $job_id = $1;
	} else{ 
	    warn( "Can't get job id from $qsub\n" );
	}
        my $flag   = 1;
	my $counter = 0;
        while ($flag) {
	    sleep($sleep);
	    $counter++;
	    warn "checking job status...\n";
	    my $output = `qstat -j $job_id 2>&1`;
	    if ( !defined($output) || $output =~ /Following jobs do not exist/ ) {
		$flag = 0;
	    }
	    if( $counter > $countmax ){
		die( "Waited too long!\n" );
	    }
        }
	die if $test_one;
    }
}
system( "date" );
    
