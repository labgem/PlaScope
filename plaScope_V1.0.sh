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
-i			fastq name (assumed to be fastq_name_1.fastq.gz / fastq_name_2.fastq.gz) [MANDATORY]
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


########################
### Contig sorting    ##
########################


contig_sorting()
{

local plascopeextendres="$1"

local contigcov=${CONTIGCOV}
local contiglength=${CONTIGLENGTH}
local hitlength=${HITLENGTH}

awk -F'\t' -v contigcov=${contigcov} -v contiglength=${contiglength} -v hitlength=${hitlength} '
BEGIN {
TPLASCOPERES[0]="unclassified"
TPLASCOPERES[1]="unclassified"
TPLASCOPERES[2]="chromosome"
TPLASCOPERES[3]="plasmid"
OFS="\t"

#skip first line
getline
}

{clab=$1; split(clab,T,"_") ; ccov=T[6];

if ( $7>=contiglength && $6>=hitlength && ccov>contigcov )  print $1,TPLASCOPERES[$3]
 
else print $1,TPLASCOPERES[0] 

}' $plascopeextendres

}



#########################################
######     Awk fasta extraction   #######
#########################################

contig_extraction()
{

local contigfile="$1"
local contigsortingfile="$2"
local contigfileprefix="$3"

awk -F'\t' -v contigfileprefix=${contigfileprefix} '
NR==FNR{Tcontig[">"$1]=$2;next}

/^>/ {  
if ($1 in Tcontig)  output=contigfileprefix"_"Tcontig[$1]".fasta"
else 
{
print "Warning:", $1, "not classified." > "/dev/stderr"
output=""
}

}

output { print >  output }' $contigsortingfile $contigfile

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

if [[ -z "${O_DIR:-}" ]]
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


#plascope variables for contig evaluation
readonly CONTIGCOV=2
readonly CONTIGLENGTH=500
readonly HITLENGTH=100


plascope

#Step 1/3

echo "Step 1/3: Running assembly with SPAdes 3.10.1"

spades.py --careful -t ${THREADS} -1 ${FASTQ_DIR}/${INPUT}_1.fastq.gz -2 ${FASTQ_DIR}/${INPUT}_2.fastq.gz -o ${OUTPUT}/${INPUT}_PlaScope/SPAdes

#Step 2/3

echo "Step 2/3: Contigs classification with Centrigue and custom database"

export CENTRIFUGE_INDEXES=${DB_DIR}
centrifuge -f --threads ${THREADS} -x ${DB_NAME} -U ${OUTPUT}/${INPUT}_PlaScope/SPAdes/contigs.fasta -k 1 --report-file ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_summary -S ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_extendedresult

#Step 3/3

echo "Step 3/3: Extraction of plasmid, chromosome and unclassified predictions"

contig_sorting ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_extendedresult > ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_list

contig_extraction ${OUTPUT}/${INPUT}_PlaScope/SPAdes/contigs.fasta  ${OUTPUT}/${INPUT}_PlaScope/Centrifuge_results/${INPUT}_list ${OUTPUT}/${INPUT}_PlaScope/PlaScope_predictions/${INPUT}

echo "If you use PlaScope please cite : ..."

exit 0
