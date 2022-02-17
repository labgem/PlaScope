#!/bin/bash

while getopts :i:o: flag; do
	case $flag in
		i) input_file=$OPTARG;;
                o) output_file=$OPTARG
	esac
done


#1. Create file with proper header to hold the results
echo -e '"Prob_Chromosome"\t"Prob_Plasmid"\t"Prediction"\t"Contig_name"\t"Contig_length"' > ${output_file}
#2. Cat the Plascope results and process line by line
cat ${input_file} | while read line
do
classification=$(echo $line | cut -f 2 -d ' ')
contig=$(echo $line | cut -f 1 -d ' ')
length=$(echo $contig | cut -f 3 -d : | cut -f 1 -d _ )
if [ $classification = 'plasmid' ]
then
echo -e 0'\t'1'\t''"Plasmid"''\t''"'$contig'"''\t'$length >> ${output_file}
elif [ $classification = 'chromosome' ]
then
echo -e 1'\t'0'\t''"Chromosome"''\t''"'$contig'"''\t'$length >> ${output_file}
elif [ $classification = 'unclassified' ]
then
echo -e 0.5'\t'0.5'\t''"Plasmid"''\t''"'$contig'"''\t'$length >> ${output_file}
fi
done

