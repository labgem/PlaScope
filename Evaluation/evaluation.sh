#!/usr/bin/env bash


##############################################################
# Author Guilhem ROYER groyer@genoscope.cns.fr | 05/07/2018  #
##############################################################

set -e
set -u
set -o pipefail


#############
#   Help    #
#############
		


usage()
{
cat << EOF
usage: evaluation.sh [OPTIONS] [ARGUMENTS]

General options:
  -h, --help		display this message
  -o			output directory [OPTIONAL] [default : current directory]
  --sample		Sample name [MANDATORY]
  --ref_plasmids	fasta file of plasmids [MANDATORY]
  --ref_chromosome	fasta file of chromosome [MANDATORY]
  --fasta		SPAdes assembly [MANDATORY]  
  --plascope_res	List of contigs and assignation from PlaScope [MANDATORY]
  --plasflow_plasmid	fasta file of plasmid prediction from Plasflow [MANDATORY]
  --plasflow_chr	fasta file of chrosomome prediction from Plasflow [MANDATORY]
  --plasflow_uc		fasta file of unclassified prediction from Plasflow [MANDATORY]
  --cBar_res		cBar result [MANDATORY]


EOF
}


#print on stderr
echoerr() { printf "Error: %s\n" "$*" >&2; }

#testfile
testfile() 
{
if [[ ! -f "$1"  ]]
then
	echoerr "File $1 not found."
	exit 1
fi

if [[ ! -s "$1"  ]]
then
	echoerr "File $1 empty."
	exit 1
fi

}

###########################
## Get unaligned contigs ##
###########################

get_unaligned()
{
local unaligned_report="$1"

awk -F'\t' '$4=="full" || ($4=="partial" && $3>($2/2)) {print $1}' $unaligned_report

}


#####################################################################
## List contigs that do not align with the chromosome AND plasmids ##
#####################################################################


sort_unaligned()
{
local unaligned_on_plasmid="$1"
local unaligned_on_chromosome="$2"


cat $unaligned_on_plasmid $unaligned_on_chromosome | sort | uniq -c | awk '$1>=2 {print $2}'
}

###################################################
## Assembly extraction without undesired contigs ##
###################################################

contig_extraction()
{

local fasta="$1"
local contigs_to_exclude="$2"

pyfasta extract --header --fasta $fasta --exclude --file $contigs_to_exclude

}


####################################
#### Get argument with getopts #####
####################################

while getopts ":1:2:o:t:-:h" optchar; do
	case "${optchar}" in
		 -)
			case "${OPTARG}" in
				help)
					usage
					exit 
					;;
				ref_plasmids)
					REF_P="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
				ref_chromosome)
					REF_C="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;					
				fasta)
					FASTA="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
				sample)
					PREFIX="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
				plascope_res)
					P_RES="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
				plasflow_plasmid)
					PL_RES_P="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
				plasflow_chr)
					PL_RES_C="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
				plasflow_uc)
					PL_RES_UC="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
				cBar_res)
					C_RES="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
			esac;;
		h)
			usage
			exit
			;;
		o)  
			O_DIR=${OPTARG}
			;;
		?)
			usage
			exit 1
			;;
	esac
done



#Check that mandatory options are not empty

if [[ -z "${REF_P:-}" ]] || [[ -z "${REF_C:-}" ]] || [[ -z "${FASTA:-}" ]] || [[ -z "${PREFIX:-}" ]] || [[ -z "${P_RES:-}" ]] || [[ -z "${PL_RES_P:-}" ]] || [[ -z "${PL_RES_C:-}" ]] || [[ -z "${PL_RES_UC:-}" ]] || [[ -z "${C_RES:-}" ]]
then
	usage
	exit 1
fi


# Set default values of optional parameters

if [[ -z "${O_DIR:-}" ]]
then
	# default value:  current directory
	O_DIR="."
fi

#Remove trailing slash of paths if exist
OUTPUT=${O_DIR%/}



################################################################
######################## Run functions  ########################
################################################################


#plascope variables for contig evaluation

readonly CONTIGCOV=2
readonly CONTIGLENGTH=500
readonly UNALIGNEDSIZE=400 #Quast option : Lower threshold for detecting partially unaligned contigs

mkdir -p ${OUTPUT}/${PREFIX}/SPAdes_filtered
mkdir -p ${OUTPUT}/${PREFIX}/tmp

#Filtering of SPAdes assembly

./filter_spades.py --cov ${CONTIGCOV} --length ${CONTIGLENGTH} --output ${OUTPUT}/${PREFIX}/SPAdes_filtered/${PREFIX}.fasta ${FASTA}


#Alignment of assembly against references (chromosome and plasmids) with quast	

quast.py --unaligned-part-size ${UNALIGNEDSIZE} -R ${REF_P} -o ${OUTPUT}/${PREFIX}/Quast_plasmids ${OUTPUT}/${PREFIX}/SPAdes_filtered/${PREFIX}.fasta 

quast.py --unaligned-part-size ${UNALIGNEDSIZE} -R ${REF_C} -o ${OUTPUT}/${PREFIX}/Quast_chromosome ${OUTPUT}/${PREFIX}/SPAdes_filtered/${PREFIX}.fasta


#Get fully and partially unaligned contigs (i.e. more than half is unaligned)

get_unaligned ${OUTPUT}/${PREFIX}/Quast_plasmids/contigs_reports/contigs_report_*.unaligned.info | sort > ${OUTPUT}/${PREFIX}/tmp/Unaligned_on_plasmid.sorted

get_unaligned ${OUTPUT}/${PREFIX}/Quast_chromosome/contigs_reports/contigs_report_*.unaligned.info | sort > ${OUTPUT}/${PREFIX}/tmp/Unaligned_on_chromosome.sorted


#Sort unaligned contigs

sort_unaligned ${OUTPUT}/${PREFIX}/tmp/Unaligned_on_plasmid.sorted ${OUTPUT}/${PREFIX}/tmp/Unaligned_on_chromosome.sorted > ${OUTPUT}/${PREFIX}/tmp/Unaligned_on_plasmid_and_chromosome

#Sort all contigs

grep "CONTIG" ${OUTPUT}/${PREFIX}/Quast_chromosome/contigs_reports/all_alignments_*.tsv | awk '{print $2}'| sort > ${OUTPUT}/${PREFIX}/tmp/All_contigs.sorted

#List Contigs aligned on plasmids and/or chromosome

comm -23 ${OUTPUT}/${PREFIX}/tmp/All_contigs.sorted ${OUTPUT}/${PREFIX}/tmp/Unaligned_on_plasmid.sorted | sort > ${OUTPUT}/${PREFIX}/tmp/Contigs_aligned_on_plasmids

comm -23 ${OUTPUT}/${PREFIX}/tmp/All_contigs.sorted ${OUTPUT}/${PREFIX}/tmp/Unaligned_on_chromosome.sorted | sort > ${OUTPUT}/${PREFIX}/tmp/Contigs_aligned_on_chromosomes

#List contigs aligned both on chromosome and plasmids

comm -12 ${OUTPUT}/${PREFIX}/tmp/Contigs_aligned_on_plasmids ${OUTPUT}/${PREFIX}/tmp/Contigs_aligned_on_chromosomes > ${OUTPUT}/${PREFIX}/tmp/Contigs_aligned_on_plasmids_and_chr

#List contigs aligned only on plasmid

comm -23 ${OUTPUT}/${PREFIX}/tmp/Contigs_aligned_on_plasmids ${OUTPUT}/${PREFIX}/tmp/Contigs_aligned_on_plasmids_and_chr > ${OUTPUT}/${PREFIX}/tmp/Contigs_plasmid_only

#List contigs aligned only on chromosome

comm -23 ${OUTPUT}/${PREFIX}/tmp/Contigs_aligned_on_chromosomes ${OUTPUT}/${PREFIX}/tmp/Contigs_aligned_on_plasmids_and_chr > ${OUTPUT}/${PREFIX}/tmp/Contigs_chr_only

#True positive, True negative, False positive, False negative, Recall, Precision, specificity, accuracy, F1_score for PlaScope


cat ${P_RES} | awk -F"\t" '$2=="plasmid" {print $1}' | sort > ${OUTPUT}/${PREFIX}/tmp/Plasmid_plascope
cat ${P_RES} | awk -F"\t" '$2=="chromosome" || $2=="unclassified" {print $1}' | sort > ${OUTPUT}/${PREFIX}/tmp/chr_UC_plascope

TP_P=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/Plasmid_plascope ${OUTPUT}/${PREFIX}/tmp/Contigs_plasmid_only | wc | awk '{print $1}' )
FP_P=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/Plasmid_plascope ${OUTPUT}/${PREFIX}/tmp/Contigs_chr_only | wc | awk '{print $1}')
TN_P=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/chr_UC_plascope ${OUTPUT}/${PREFIX}/tmp/Contigs_chr_only | wc | awk '{print $1}')
FN_P=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/chr_UC_plascope ${OUTPUT}/${PREFIX}/tmp/Contigs_plasmid_only | wc | awk '{print $1}')

Recall_P=$(echo "scale=3;$TP_P / ($TP_P + $FN_P)" | bc -l | xargs printf "%.2f")
Precision_P=$(echo "scale=3;$TP_P/($TP_P + $FP_P)" | bc -l | xargs printf "%.2f")
Specificity_P=$(echo "scale=3;$TN_P/($FP_P+$TN_P)" | bc -l | xargs printf "%.2f")
Accuracy_P=$(echo "scale=3;($TN_P+$TP_P)/($TP_P+$TN_P+$FP_P+$FN_P)" | bc -l | xargs printf "%.2f")
F1_score_P=$(echo "scale=3;(2*$Recall_P*$Precision_P)/($Recall_P+$Precision_P)" | bc -l | xargs printf "%.2f")

#True positive, True negative, False positive, False negative, Recall, Precision, specificity, accuracy, F1_score for Plaflow

cat ${PL_RES_P} | grep ">" | sed 's$>$$' | awk '{print $1}' | sort > ${OUTPUT}/${PREFIX}/tmp/Plasmid_plasflow
cat ${PL_RES_C} ${PL_RES_UC} |  grep ">" | sed 's$>$$' | awk '{print $1}' | sort > ${OUTPUT}/${PREFIX}/tmp/chr_UC_plasflow

TP_PL=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/Plasmid_plasflow ${OUTPUT}/${PREFIX}/tmp/Contigs_plasmid_only | wc | awk '{print $1}' )
FP_PL=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/Plasmid_plasflow ${OUTPUT}/${PREFIX}/tmp/Contigs_chr_only | wc | awk '{print $1}')
TN_PL=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/chr_UC_plasflow ${OUTPUT}/${PREFIX}/tmp/Contigs_chr_only | wc | awk '{print $1}')
FN_PL=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/chr_UC_plasflow ${OUTPUT}/${PREFIX}/tmp/Contigs_plasmid_only | wc | awk '{print $1}')

Recall_PL=$(echo "scale=3;$TP_PL / ($TP_PL + $FN_PL)" | bc -l | xargs printf "%.2f")
Precision_PL=$(echo "scale=3;$TP_PL/($TP_PL + $FP_PL)" | bc -l | xargs printf "%.2f")
Specificity_PL=$(echo "scale=3;$TN_PL/($FP_PL+$TN_PL)" | bc -l | xargs printf "%.2f")
Accuracy_PL=$(echo "scale=3;($TN_PL+$TP_PL)/($TP_PL+$TN_PL+$FP_PL+$FN_PL)" | bc -l | xargs printf "%.2f")
F1_score_PL=$(echo "scale=3;(2*$Recall_PL*$Precision_PL)/($Recall_PL+$Precision_PL)" | bc -l | xargs printf "%.2f")

#True positive, True negative, False positive, False negative, Recall, Precision, specificity, accuracy, F1_score for cBar

cat ${C_RES} |  awk -F"\t" '$3=="Plasmid" {print $1}' | sort > ${OUTPUT}/${PREFIX}/tmp/Plasmid_cBar
cat ${C_RES} |  awk -F"\t" '$3=="Chromosome" {print $1}' | sort > ${OUTPUT}/${PREFIX}/tmp/chr_cBar

TP_C=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/Plasmid_cBar ${OUTPUT}/${PREFIX}/tmp/Contigs_plasmid_only | wc | awk '{print $1}' )
FP_C=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/Plasmid_cBar ${OUTPUT}/${PREFIX}/tmp/Contigs_chr_only | wc | awk '{print $1}')
TN_C=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/chr_cBar ${OUTPUT}/${PREFIX}/tmp/Contigs_chr_only | wc | awk '{print $1}')
FN_C=$(comm -12 ${OUTPUT}/${PREFIX}/tmp/chr_cBar ${OUTPUT}/${PREFIX}/tmp/Contigs_plasmid_only | wc | awk '{print $1}')

Recall_C=$(echo "scale=3;$TP_C / ($TP_C + $FN_C)" | bc -l | xargs printf "%.2f")
Precision_C=$(echo "scale=3;$TP_C/($TP_C + $FP_C)" | bc -l | xargs printf "%.2f")
Specificity_C=$(echo "scale=4;$TN_C/($FP_C+$TN_C)" | bc -l | xargs printf "%.2f")
Accuracy_C=$(echo "scale=3;($TN_C+$TP_C)/($TP_C+$TN_C+$FP_C+$FN_C)" | bc -l | xargs printf "%.2f")
F1_score_C=$(echo "scale=3;(2*$Recall_C*$Precision_C)/($Recall_C+$Precision_C)" | bc -l | xargs printf "%.2f")

#Print performance results of each method

echo -e Sample"\t"Method"\t"TP"\t"FP"\t"TN"\t"FN"\t"Recall"\t"Precision"\t"Specificity"\t"Accuracy"\t"F1_score"\n"${PREFIX}"\t"PlaScope"\t"${TP_P}"\t"${FP_P}"\t"${TN_P}"\t"${FN_P}"\t"${Recall_P}"\t"${Precision_P}"\t"${Specificity_P}"\t"${Accuracy_P}"\t"${F1_score_P} > ${OUTPUT}/${PREFIX}/Classifiers_performance.txt

echo -e ${PREFIX}"\t"Plaflow"\t"${TP_PL}"\t"${FP_PL}"\t"${TN_PL}"\t"${FN_PL}"\t"${Recall_PL}"\t"${Precision_PL}"\t"${Specificity_PL}"\t"${Accuracy_PL}"\t"${F1_score_PL} >> ${OUTPUT}/${PREFIX}/Classifiers_performance.txt

echo -e ${PREFIX}"\t"cBar"\t"${TP_C}"\t"${FP_C}"\t"${TN_C}"\t"${FN_C}"\t"${Recall_C}"\t"${Precision_C}"\t"${Specificity_C}"\t"${Accuracy_C}"\t"${F1_score_C} >> ${OUTPUT}/${PREFIX}/Classifiers_performance.txt




exit 0

