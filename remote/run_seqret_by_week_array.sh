#!/bin/bash
#
#$ -S /bin/bash
#$ -l arch=linux-x64
##$ -l h_rt=200:0:0
#$ -l h_rt=0:29:0
#$ -l scratch=2G
#$ -pe smp 2
#$ -cwd
#$ -o /dev/null
#$ -e /dev/null

#for big memory (>24G), add this
# #$ -l xe5520=true
#else, set memory here
#$ -l mem_free=1G

#the array job is run from the command line via -t, eg
#qsub -t 1-102

FASTQDIR=$1
FASTADIR=$2

#index the files in the directory for array jobs
fs=(`ls ${FASTQDIR}/*.fastq*`)
i=$(expr ${SGE_TASK_ID} - 1)
f=${fs[$i]}

#build the output location
mkdir -p $FASTADIR

#prepare the input and output paths for seqret

FILE=${f}
echo "processing ${FILE}"
PREFIX=$(basename ${FILE} | sed 's/\.fastq.*//')
#files are initially gzipped
INSUFFIX=.fastq
INPUT=${FASTQDIR}${PREFIX}${INSUFFIX}
OUTSUFFIX=.fa
OUTPUT=${FASTADIR}${PREFIX}${OUTSUFFIX}

#this may not be a perfect control statement for 
#restarting failed jobs....
if [ -e $OUTPUT ]
then
    exit
fi

LOGS=/scrapp/sharpton/data/ibdmouse/logs/seqret
mkdir -p $LOGS
LOG=${LOGS}/${JOB_ID}.${SGE_TASK_ID}.log

uname -a                                       > $LOG 2>&1
echo "****************************"            >> $LOG 2>&1
echo "RUNNING SEQRET WITH $*"                  >> $LOG 2>&1
source /netapp/home/sharpton/.bash_profile     >> $LOG 2>&1
date                                           >> $LOG 2>&1

if [ -e ${INPUT}.gz ]
then
   gunzip ${INPUT}.gz >> $LOG 2>&1
fi

echo "seqret -sequence $INPUT -outseq $OUTPUT -sformat1 fastq -osformat2 fasta" >> $LOG 2>&1
seqret -sequence $INPUT -outseq $OUTPUT -sformat1 fastq -osformat2 fasta        >> $LOG 2>&1

gzip $INPUT >> $LOG 2>&1

date                                           >> $LOG 2>&1
echo "RUN FINISHED"                            >> $LOG 2>&1
#qstat -f -j ${JOB_ID}.${SGE_TASK_ID}           >> $LOG 2>&1