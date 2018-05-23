#!/usr/bin/env bash


##############################################################
# Author Guilhem ROYER groyer@genoscope.cns.fr | 06/04/2018  #
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
usage: PlaScope.sh [OPTIONS] [ARGUMENTS]

-h, --help		display this message
-t			number of threads[OPTIONAL] [default : 8] 
-i			fastq name (assumed to be filename_1.fastq.gz / filename_2.fastq.gz) [MANDATORY]
--fastq_dir		path to fastq directory [MANDATORY]
-o			output directory [OPTIONAL] [default : current directory]
--db_dir		path to centrifuge database [MANDATORY]
--db_name		centrifuge database name [MANDATORY]

Wrapper to launch PlaScope (SPAdes + Centrifuge-based plasmidic sequences classification)


EOF
}


################################
#  Just a little bit of art    #
################################


plascope()
{
cat << "EOF"

# MNXXXXXXXXXXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXXXXXXXXXXXXXXXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
No'''''''''''''cOWMMWKOOOXWMMMMMMMMMMMMMMWKO0OO0000O0XMMMMNk;''''''''''''',:dXMWX00000000OO0O0NMMMN0O000000OOKNMMWX0000000000OKWMMMN0O000000000000O0NM
N:              .:0W0,   cNMMMMMMMMMMMMWO:.          'dXM0;              ,xKNWKl.          .,xNMNx,.         .;kNNc           .:0WMO'            .'dXM
N:   .:lllll;     ,00'   :NMMMMMMMMMMMWd.              ;0d    ,llllllllokNMMMO'           'dXMMX:               oX:             .lXk.           .lKWMM
N:   ,KMWWKl.   .c0W0'   :NMMMMMMMMMMMN:   .okkkkkk;   .kd   .xMMMMMMMMMMMMMMd.   :kkkkkkOXMMMM0'   ,xkkkkkd.   ;K:   .okd;     ,kNk.   ;kkkkkkkKWMMMM
N:   ,KWKl.   .c0WMM0'   :NMMMMMMMMMMMN:   'OOxxxxx;   .kd    cOkkkkkkOkOXMMMd.  .xMMMMMMMMMMMM0'   cWMMMMMX;   ;K:   ,Ox,    ,xNMMk.   ;xxxxxxONMMMMM
N:   'ko.   .c0WMMMM0'   :NMMMMMMMMMMMN:   .:.         .kO.              'dOXd   .xMMMMMMMMMMMM0'   cWMMMMMX;   ;K:   .:.   ,xNMMMMk.          .OMMMMM
N:   .:.  .:OWMMMMMM0'   :NMMMMMMMMMMMN:   'kOxxxxx;   .kWKl.               :l.  .xMMMMMMMMMMMM0'   cWMMMMMX;   ;K:   ,kd,,xNMMMMMMk.   ,xxxxxxONMMMMM
N:   ,0O:cOWMMMMMMMM0'   ,k0O0000OO0OKN:   '0MMMMMMo   .kMMWXOOOOOOOOOk,    ':.   c0OO000000O0X0'   ,k0O0OOx'   ;K:   ,KWNNMMMMMMMMk.   :O000000O00OXM
N:   ,KMWWMMMMMMMMMM0'               :Kc   '0MMMMMMo   .kMMMMMMMMMMMMMNc    'o'              .dK;               lK:   ,KMMMMMMMMMMMk.               cN
N:   ,KMMMMMMMMMMMMM0,               ;Kc   ,0MMMMMWo   .k0lcccccccccccc.    'O0c.             oWXo.           ,xNN:   ,KMMMMMMMMMMMk.               cN
N:   ,KMMMMMMMMMMMMMN0kkkkkkkkkkkkkkk0WKkkk0WMMMMMMXOkkONd                .;dNMWKkkkkkkkkkkkkkXMMMXOkkkkkkkkkONMMWKkkk0WMMMMMMMMMMMNOkkkkkkkkkkkkkkkKW
No',,lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;,,,',,,,,,,,,,lKWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MWNWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

EOF
}


#print on stderr
echoerr() { printf "%s\n" "$*" >&2; }

####################
### SPAdes 3.10.1 ##
####################

assembly()
{
spades.py --careful -t ${THREADS} -1 ${FASTQ_DIR}/${INPUT}_1.fastq.gz -2 ${FASTQ_DIR}/${INPUT}_2.fastq.gz -o ${OUTPUT}/${INPUT}_PlaScope/SPAdes
}


########################
### Centrifuge 1.0.3b ##
########################


classification()
{
export CENTRIFUGE_INDEXES=${DB_DIR}
centrifuge -f --threads ${THREADS} -x ${DB_NAME} -U ${OUTPUT}/${INPUT}_PlaScope/SPAdes/contigs.fasta -k 1 --report-file ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_summary -S ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_extendedresult
}


########################
### Sequences sorting ##
########################



plasmid_sorting()
{
awk -F'\t' '$3==3 && $7>=500 && $6>=100 {print $1}' ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_extendedresult | awk -F'_' '$6>2 {print $0}' > ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_plasmidlist
}

chromosome_sorting()
{
awk -F'\t' '$3==2 && $7>=500 && $6>=100 {print $1}' ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_extendedresult |  awk -F'_' '$6>2 {print $0}' > ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_chromosomelist
}

unclassified_sorting()
{
awk -F'\t' '$3==1 && $7>=500 && $6>=100 {print $1}' ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_extendedresult |  awk -F'_' '$6>2 {print $0}' > ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_unclassifiedlist
}



#########################################
######     Awk fasta extraction   #######
#########################################


chromosome_extraction()
{
awk 'NR==FNR{a[">"$0];next}/^>/{f=0;}($0 in a)||f{print;f=1}' ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_chromosomelist ${OUTPUT}/${INPUT}_PlaScope/SPAdes/contigs.fasta > ${OUTPUT}/${INPUT}_PlaScope/PlaScope_predictions/${INPUT}_chromosome.fasta
}

plasmid_extraction()
{
awk 'NR==FNR{a[">"$0];next}/^>/{f=0;}($0 in a)||f{print;f=1}' ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_plasmidlist ${OUTPUT}/${INPUT}_PlaScope/SPAdes/contigs.fasta > ${OUTPUT}/${INPUT}_PlaScope/PlaScope_predictions/${INPUT}_plasmid.fasta
}

UC_extract()
{
awk 'NR==FNR{a[">"$0];next}/^>/{f=0;}($0 in a)||f{print;f=1}' ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_unclassifiedlist ${OUTPUT}/${INPUT}_PlaScope/SPAdes/contigs.fasta > ${OUTPUT}/${INPUT}_PlaScope/PlaScope_predictions/${INPUT}_unclassified.fasta
}

####################################
#### Get argument with getopts #####
####################################

while getopts ":i:o:d:t:-:h" optchar; do
	case "${optchar}" in
		 -)
			case "${OPTARG}" in
				help)
					usage
					exit
					;;
				db_dir)
					CENTRI_DIR="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
				db_name)
					DB_NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;					
				fastq_dir)
					FQ_DIR="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
			esac;;
		h)
			usage
			exit
			;;
		i)
			INPUT=${OPTARG}
			;;
		t)
			THREADS=${OPTARG}
			;;
		o)  
			O_DIR=${OPTARG}
			;;
		?)
			usage
			exit
			;;
	esac
done




if [[ -z "${INPUT:-}" ]] || [[ -z "${CENTRI_DIR:-}" ]] || [[ -z "${DB_NAME:-}" ]] 
then
	usage
	exit
fi

# Set default values of optional parameters
if [[ -z "${THREADS:-}" ]]
then
	# default value:  8
	THREADS=8
fi

if [[ -z "${FQ_DIR:-}" ]]
then
	# default value:  current directory
	FQ_DIR="."
fi

if [[ -z "${FQ_DIR:-}" ]]
then
	# default value:  current directory
	O_DIR="."
fi
#Remove trailing slash of paths if exist
FASTQ_DIR=${FQ_DIR%/}
DB_DIR=${CENTRI_DIR%/}
OUTPUT=${O_DIR%/}

########################
#### Run functions #####
########################


if [[ -d "${OUTPUT}/${INPUT}_PlaScope/PlaScope_predictions" ]]
then
	echoerr "${OUTPUT}/${INPUT}_PlaScope/PlaScope_predictions already exists"
	exit 1
else
mkdir -p ${OUTPUT}/${INPUT}_PlaScope/PlaScope_predictions
fi

if [[ -d "${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results" ]]
then
	echoerr "${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results already exists"
	exit 1
else
mkdir -p  ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results
fi

plascope

#Step 1/3

echo "Step 1/3: Running assembly with SPAdes 3.10.1"

assembly

#Step 2/3

echo "Step 2/3: Contigs classification with Centrigue and custom database"

classification

#Step 3/3

echo "Step 3/3: Extraction of plasmid, chromosome and unclassified predictions"

plasmid_sorting
plasmid_extraction
chromosome_sorting
chromosome_extraction
unclassified_sorting
UC_extract

echo "If you use PlaScope please cite : ..."

exit 0
