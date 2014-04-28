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

INDIR=$1
OUTDIR=$2
INSUFFIX=$3 #e.g.,  .fa
OUTSUFFIX=$4 #e.g., .pep

#index the files in the directory for array jobs
fs=(`ls ${INDIR}/*${SEARCHPATTERN}*`)
i=$(expr ${SGE_TASK_ID} - 1)
f=${fs[$i]}

#build the output location
mkdir -p $OUTDIR

#prepare the input and output paths for seqret

FILE=${f}
echo "processing ${FILE}"
PREFIX=$(basename ${FILE} | sed "s/${INSUFFIX}.*//")
#files are initially gzipped
INPUT=${INDIR}${PREFIX}${INSUFFIX}
OUTPUT=${OUTDIR}${PREFIX}${OUTSUFFIX}

#this may not be a perfect control statement for 
#restarting failed jobs....
if [ -e $OUTPUT ]
then
    exit
fi

LOGS=/scrapp/sharpton/data/ibdmouse/logs/transeq
mkdir -p $LOGS
LOG=${LOGS}/${JOB_ID}.${SGE_TASK_ID}.log

uname -a                                       > $LOG 2>&1
echo "****************************"            >> $LOG 2>&1
echo "RUNNING TRANSEQ WITH $*"                  >> $LOG 2>&1
source /netapp/home/sharpton/.bash_profile     >> $LOG 2>&1
date                                           >> $LOG 2>&1

if [ -e ${INPUT}.gz ]
then
   gunzip ${INPUT}.gz >> $LOG 2>&1
fi

echo "transeq -trim -frame=6 -sformat1 pearson -osformat2 pearson $INPUT $OUTPUT" >> $LOG 2>&1
transeq -trim -frame=6 -sformat1 pearson -osformat2 pearson $INPUT $OUTPUT >> $LOG 2>&1

#gzip $INPUT >> $LOG 2>&1

date                                           >> $LOG 2>&1
echo "RUN FINISHED"                            >> $LOG 2>&1
#qstat -f -j ${JOB_ID}.${SGE_TASK_ID}           >> $LOG 2>&1