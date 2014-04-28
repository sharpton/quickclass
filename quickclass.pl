#!/usr/bin/perl -w

use strict;
use Getopt::Long;

my( $sample, $week );
my $rdatabase = "/netapp/home/sharpton/projects/mouse_microbiome/lastdb/prelim/All_Morgan_KO.fa";
my $build = 0; #build a fasta data repository from raw fastq results. Must do 1 time for each sample-week
my $rdatadir = "/scrapp2/sharpton/ibdmouse/by_week/";

my $GLOBAL_SSH_TIMEOUT_OPTIONS_STRING = '-o TCPKeepAlive=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=480';

GetOptions(
    "s=s" => \$sample,
    "w=s" => \$week,
    "d:s" => \$rdatabase,
    "build" => \$build,
    );

if( !defined($sample) ){ die( "You must define a sample with -s\n" ) };
if( !defined($week) ){ die( "You must define a week with -w\n" ) };

my $fastq_data_dir = "/mnt/data/home/sharpton/data/ibdmouse/raw/by_week/week${week}/${sample}_${week}/fastq/";
my $remote_fastq   = $rdatadir . "week${week}/${sample}_${week}/fastq/";
my $connect_str    = 'sharpton@chef.compbio.ucsf.edu';
#Create some structure, by week
if( $build ){
    `perl /mnt/data/home/sharpton/data/ibdmouse/scripts/link_weekly_files.pl -w ${week} -s ${sample}`;

    #QC?

    #Convert to Fasta
    #this takes too long...
    #`perl /mnt/data/home/sharpton/data/ibdmouse/scripts/fastq2fasta.pl -w ${week} -s ${sample}`;

    #For this pipeline, we will need to just run fastq against lastdb.
    print("ssh $connect_str \"mkdir -p $remote_fastq\"'\n");
    `ssh $connect_str "mkdir -p $remote_fastq"`;
    print("rsync -avL $fastq_data_dir ${connect_str}:$remote_fastq\n");
    `rsync -avL $fastq_data_dir/*.gz ${connect_str}:$remote_fastq`;
}



#run the search
my $cmd = "perl /netapp/home/sharpton/projects/mouse_microbiome/scripts/job_launcher.pl -w $week -s $sample -m lastal -is fastq -os lastal";
print( "ssh $GLOBAL_SSH_TIMEOUT_OPTIONS_STRING $connect_str $cmd\n" );
`ssh $GLOBAL_SSH_TIMEOUT_OPTIONS_STRING $connect_str $cmd`;

#cat the results
$cmd = "perl /netapp/home/sharpton/projects/mouse_microbiome/scripts/job_launcher.pl -w $week -s $sample -m catresults -is lastal -os catresults";
print( "ssh $GLOBAL_SSH_TIMEOUT_OPTIONS_STRING $connect_str $cmd\n" );
`ssh $GLOBAL_SSH_TIMEOUT_OPTIONS_STRING $connect_str $cmd`;

#cat the results
$cmd = "perl /netapp/home/sharpton/projects/mouse_microbiome/scripts/job_launcher.pl -w $week -s $sample -m parseresults -is catresults -os parsed";
print( "ssh $GLOBAL_SSH_TIMEOUT_OPTIONS_STRING $connect_str $cmd\n" );
`ssh $GLOBAL_SSH_TIMEOUT_OPTIONS_STRING $connect_str $cmd`;

