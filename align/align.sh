#!/bin/bash
set -e
set -x
set -o pipefail

input=$(./swe get input | ./swe fetch -)
sample=$(./swe get sample_id)
gatk_data=$(./swe get GATK_DATA)
cpu_cores=32
GROUP_ID="@RG\tID:1\tPL:ILLUMINA\tPU:pu\tLB:group1\tSM:Sample_XXX"


#cat $input > aligned.bam
#./swe emit file aligned.bam


bwa mem -M -p -t $cpu_cores -R "$GROUP_ID" $gatk_data/hg19/ucsc.hg19.fasta $input \
    | samtools view -@ $cpu_cores -1 -bt   $gatk_data/hg19/ucsc.hg19.fasta.fai - \
    | samtools sort -@ $cpu_cores -l 0 - raw

samtools index raw.bam

chr_list=$(samtools idxstats raw.bam| cut -f 1 |grep chr)
for chr in $chr_list
do
	samtools view -@ $cpu_cores -F 4 -b raw.bam  $chr > $chr.bam
	samtools index $chr.bam 
	# run emits in parallel
	{ ./swe emit file $chr.bam     || touch emit.failed & }
	{ ./swe emit file $chr.bam.bai || touch emit.failed & }

done

wait
[ ! -e emit.failed ]

#	samtools view -@ $cpu_cores -f 4 -b raw.bam  > unaligned.bam
#	samtools index unaligned.bam
#	./swe emit file unaligned.bam
#	./swe emit file unaligned.bam.bai

exit 0