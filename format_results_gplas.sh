#!/bin/bash

while getopts :i:o:a:p: flag; do
	case $flag in
		i) input_file=$OPTARG;;
                o) output_file=$OPTARG;;
                p) plascope_directory=$OPTARG;;
                a) assembler=$OPTARG
	esac
done


#1. Create file with proper header to hold the results
echo -e '"Prob_Chromosome"\t"Prob_Plasmid"\t"Prediction"\t"Contig_name"\t"Contig_length"' > ${output_file}
#2. Cat the Plascope results and process line by line
if [[ $assembler == 'unicycler' ]]
then
tail -n+2 ${input_file} | while read line
do
classification=$(echo $line | cut -f 3 -d ' ')
contig_number=$(echo $line | cut -f 1 -d ' ')
echo 'contig_number',${contig_number}
contig=$(grep -w '>'${contig_number} ${plascope_directory}*fasta | cut -f 2 -d : | sed 's/>//g' )
length=$(echo $line | cut -f 7 -d ' ')
if [ $classification == '3' ]
then
echo -e 0'\t'1'\t''"Plasmid"''\t''"'$contig'"''\t'$length >> ${output_file}
elif [ $classification == '2' ]
then
echo -e 1'\t'0'\t''"Chromosome"''\t''"'$contig'"''\t'$length >> ${output_file}
else
echo -e 0.5'\t'0.5'\t''"Plasmid"''\t''"'$contig'"''\t'$length >> ${output_file}
fi
done

else
tail -n+2 ${input_file} | while read line
do
classification=$(echo $line | cut -f 3 -d ' ')
contig=$(echo $line | cut -f 1 -d ' ')
length=$(echo $line | cut -f 7 -d ' ')
if [ $classification == '3' ]
then
echo -e 0'\t'1'\t''"Plasmid"''\t''"'$contig'"''\t'$length >> ${output_file}
elif [ $classification == '2' ]
then
echo -e 1'\t'0'\t''"Chromosome"''\t''"'$contig'"''\t'$length >> ${output_file}
else                                     
echo -e 0.5'\t'0.5'\t''"Plasmid"''\t''"'$contig'"''\t'$length >> ${output_file}
fi
done
fi
