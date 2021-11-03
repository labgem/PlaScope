#!/usr/bin/env bash


# Copyright 2018, Guilhem Royer <groyer@genoscope.cns.fr>
#
# This file is part of PlaScope.
#
# PlaScope is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# PlaScope is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PlaScope.  If not, see <http://www.gnu.org/licenses/>.

##############################################################
# Author Guilhem ROYER groyer@genoscope.cns.fr | 06/04/2018  #
##############################################################

VERSION=1.3

set -e
set -u
set -o pipefail


#############
#   Help    #
#############

version()
{
cat << EOF
$VERSION
EOF
}

usage()
{
cat << EOF
usage: plaScope.sh [OPTIONS] [ARGUMENTS]

General options:
  -h, --help		display this message and exit
  -v, --version		display version number and exit
  -n, --no-banner	don't print beautiful banners
  -t			number of threads[OPTIONAL] [default : 8]
  -o			output directory [OPTIONAL] [default : current directory]
  --sample		Sample name [MANDATORY]
  --db_dir		path to centrifuge database [MANDATORY]
  --db_name		centrifuge database name [MANDATORY]

Mode 1: SPAdes assembly + contig classification
  -1			forward paired-end reads [MANDATORY]
  -2			reverse paired-end reads [MANDATORY]


Mode 2: contig classification of a fasta file (only if you already have your SPAdes or Unicycler assembly!)
  --fasta		SPAdes or Unicycler assembly fasta file [MANDATORY]
  -a			Specify the assembler used: spades or unicycler [MANDATORY]


Example mode 1:
plaScope.sh -1 my_reads_1.fastq.gz -2 my_reads_2.fastq.gz -o output_directory  --db_dir path/to/DB --db_name chromosome_plasmid_db --sample name_of_my_sample

Example mode 2:
plaScope.sh --fasta my_fastafile.fasta -o output_directory --db_dir path/to/DB --db_name chromosome_plasmid_db --sample name_of_my_sample



Github:
https://github.com/GuilhemRoyer/PlaScope

EOF
}


################################
#  Just a little bit of art    #
################################


plascope()
{

if [[ ${NO_BANNER} -eq 1 ]]
then
	return
fi

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

mode_1()
{

if [[ ${NO_BANNER} -eq 1 ]]
then
	echo "Mode 1"
	return
fi

cat << "EOF"

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMWKkkkONMMMMMN0kkk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kkkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkkk0NMMMMMMMMM
MMMMMWl   .oOXWXOd.   ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMX;   cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXk;   ,0MMMMMMMMM
MMMMMWl     .oKo.     ;KMMMMWXXXXXXNWMMMMMMMMMMMMMMK;   :NMMMMMMMMNXXXXXXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl..   '0MMMMMMMMM
MMMMMWl      ...      ;KMMMWO;.....:KMMMMMMMMMMWWWW0;   :XMMMMMMMNo.....'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMWXO;   '0MMMMMMMMM
MMMMMWl               ;KMM0l'  ;xc..,ckWMMMMMMWk;,,'    :NMMMMMNx;. .lxxxl:oXMMMMMMMMMMMMMMMMMMMMMMMMMMMNl   '0MMMMMMMMM
MMMMMWl   .:l. .lc.   ;KMMx.   oWk.   lNMMMMNko, 'll.   :NMMMMMX:   .,cc:. '0MMMMMMMMMMMMMMMMMMMMMMMMMMMNc   '0MMMMMMMMM
MMMMMWl   .ONxcxWK,   ;KMMx.   oWk.   lNMMMM0,   cNK;   :NMMMMMX:   .;cccccdXMMMMMMMMMMMMMMMMMMMMMMMMMMMNc   ,0MMMMMMMMM
MMMMMWl   .OMMMMM0,   ;KMM0:.  :kl. .;xWMMMMK:.. ,xx;.  ,xKWMMMNd'. .okkOXWMMMMMMMMMMMMMMMMMMMMMMMMMN0OOx,   .oOOOKWMMMM
MMMMMWd...;0MMMMMKc...cXMMWNO;.....:0WWMMMMMWNKo...;xOc..'lXMMMMWXl...'.,xWMMMMMMMMMMMMMMMMMMMMMMMMWO;''.......'.'dNMMMM
MMMMMMNXXXXWMMMMMWNXXXNWMMMMWXXXXXXNWMMMMMMMMMMNXXXXWWNXXXNWMMMMMMNXKXXXXNMMMMMMMMMMMMMMMMMMMMMMMMMMWXXXXXXXXXXXXXNMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

EOF
}


mode_2()
{

if [[ ${NO_BANNER} -eq 1 ]]
then
	echo "Mode 2"
	return
fi

cat << "EOF"


MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWNNNNWMMMMMWNNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNNNNNNWMMMMMMMMM
MMMWx'..:OWWMWN0c..'oNMMMMMMMMMMMMMMMMMMMMMMMMMMMXl..'oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXo''''''''''dXWWMMMMMM
MMMWl    .;kWk,.    :NMMMMMMMMMMMMMMMMMMMMMMMMMMMK,   ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:'. ;xxxxxd, .'cKMMMMMM
MMMWl      ':'      :XMMMMKocccccdXMMMMMMMMMMMMMMK,   ;XMMMMMMMWOccccclOWMMMMMMMMMMMMMMMMMMMMMMMXkddxKMMMNx:.   .OMMMMMM
MMMWl               :XMMXk:. .c, .cxKMMMMMMMM0ooo:.   ;XMMMMMW0d' .;cccodkNMMMMMMMMMMMMMMMMMMMMMMMMMW0xddl.   'lxXMMMMMM
MMMWl    ',. .,,.   :XMMk.   oWk.   oWMMMMWX0: .,,.   ;XMMMMMNc   .lxxd, '0MMMMMMMMMMMMMMMMMMMMMMMWKx,      .,xWMMMMMMMM
MMMWl   .OXl.oN0,   :XMMk.   oWk.   oWMMMMK;.  :XK,   ;XMMMMMN:    .''''.cKMMMMMMMMMMMMMMMMMMMMMNKk;    ...'dNWMMMMMMMMM
MMMWl   .OMNXNMK,   :XMMO'   lXx.  .dWMMMMK,   ;0O,   ,0NMMMMNl.  .d000KNNWMMMMMMMMMMMMMMMMMMMMMO'     .d000KXXXNWMMMMMM
MMMWl   'OMMMMMK,   :NMMNKo. ... .dKNMMMMMW0k: ..,od' ..lXMMMWXO;  .'',xWMMMMMMMMMMMMMMMMMMMMMMMk.      .''''''..cKMMMMM
MMMMKkkkONMMMMMW0kkkKWMMMMNOkkkkk0NMMMMMMMMMMXkkkOXW0kkk0WMMMMMWKkkkkkkKMMMMMMMMMMMMMMMMMMMMMMMMNOkkkkkkkkkkkkkkONMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

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

########################
### Contig sorting    ##
########################


contig_sorting_unicycler()
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

{clab=$1; split(clab,T,":") ; ccov=T[5];

if ( $7>=contiglength && $6>=hitlength && ccov>contigcov )  print $1,TPLASCOPERES[$3]
	
#test if this could be fixed
#if ( $6>=hitlength )  print $1,TPLASCOPERES[$3]

else print $1,TPLASCOPERES[0]

}' $plascopeextendres

}

contig_sorting_spades()
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

#test if this could be fixed
#if ( $6>=hitlength )  print $1,TPLASCOPERES[$3]

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

while getopts ":1:2:o:t:-:h:v:n:a:" optchar; do
	case "${optchar}" in
		 -)
			case "${OPTARG}" in
				help)
					usage
					exit
					;;
				version)
					version
					exit;;
				no-banner)
					NO_BANNER=1
					;;
				db_dir)
					CENTRI_DIR="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
				db_name)
					DB_NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
				fasta)
					FASTA="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
				sample)
					PREFIX="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					;;
			esac;;
		h)
			usage
			exit
			;;
		v)
			version
			exit
			;;
		n)
			NO_BANNER=1
			;;
		1)
			READ1=${OPTARG}
			;;
		2)
			READ2=${OPTARG}
			;;
		t)
			THREADS=${OPTARG}
			;;
		o)
			O_DIR=${OPTARG}
			;;
		a)
			assembler=${OPTARG}
			;;
		?)
			usage
			exit 1
			;;
	esac
done


#MODE 1 or 2
MODE=""

#Check that mandatory options are not empty

if [[ -z "${CENTRI_DIR:-}" ]] || [[ -z "${DB_NAME:-}" ]] || [[ -z "${PREFIX:-}" ]]
then
	usage
	exit 1
fi


if [[ ( -z "${FASTA:-}" ) && ( ( -z "${READ1:-}" ) || ( -z "${READ2:-}" ) ) ]]
then
	usage
	exit 1
fi


#Check that "mode 1" and "mode 2" are not used at the same time

if [[  "${FASTA:-}" && ( "${READ1:-}" || "${READ2:-}" )  ]]
then
	echoerr "Mode 1 and mode 2 can't be run at the same time. Please provide fastq files (mode 1) OR a fasta file (mode 2)"
	usage
	exit 1
fi

if [[ "${FASTA:-}" ]]
then
	MODE=2

	testfile "${FASTA}"

elif [[ "${READ1:-}" &&  "${READ2:-}"  ]]
then
	MODE=1

	testfile "${READ1}"
	testfile "${READ2}"
else
	usage
	exit 1
fi

# default value: use banner
NO_BANNER=${NO_BANNER-0}

# Set default values of optional parameters
if [[ -z "${THREADS:-}" ]]
then
	# default value:  8
	THREADS=8
fi

if [[ -z "${O_DIR:-}" ]]
then
	# default value:  current directory
	O_DIR="."
fi

#Remove trailing slash of paths if exist
DB_DIR=${CENTRI_DIR%/}
OUTPUT=${O_DIR%/}

#Check if directories already exist


if [[ -d "${OUTPUT}/${PREFIX}_PlaScope/PlaScope_predictions" ]]
then
	echoerr "${OUTPUT}/${PREFIX}_PlaScope/PlaScope_predictions already exists"
	exit 1
else
mkdir -p ${OUTPUT}/${PREFIX}_PlaScope/PlaScope_predictions
fi

if [[ -d "${OUTPUT}/${PREFIX}_PlaScope/Centrifuge_results" ]]
then
	echoerr "${OUTPUT}/${PREFIX}_PlaScope/Centrifuge_results already exists"
	exit 1
else
mkdir -p  ${OUTPUT}/${PREFIX}_PlaScope/Centrifuge_results
fi


################################################################
######################## Run functions  ########################
################################################################


#plascope variables for contig evaluation

if [[ $assembler = 'unicycler' ]]
then
readonly CONTIGCOV=0

elif [[ $assembler = 'spades' ]]
then
readonly CONTIGCOV=2

else echo "provide valid assembler name: spades or unicycler" && exit 0
fi

readonly CONTIGLENGTH=500
readonly HITLENGTH=100

step=1

plascope


if [[ "${MODE}" == 1 ]]
then
	mode_1
	echo "Step $step: Running assembly with SPAdes"

	# SPAdes automatically stores its log in ${OUTPUT}/${PREFIX}_PlaScope/SPAdes/spades.log so we redirect output to /dev/nulll
	echo SPAdes log can be found here: ${OUTPUT}/${PREFIX}_PlaScope/SPAdes/spades.log
	spades.py --careful -t ${THREADS} -1 ${READ1} -2 ${READ2} -o ${OUTPUT}/${PREFIX}_PlaScope/SPAdes &> /dev/null

	FASTA="${OUTPUT}/${PREFIX}_PlaScope/SPAdes/contigs.fasta"
	(( step++ ))
else
	mode_2

fi

echo "Step $step: Contigs classification with Centrifuge and custom database"

export CENTRIFUGE_INDEXES=${DB_DIR}

# We don't need centrifuge output but we still redirect stdout and stderr to a file
CENTRIFUGE_LOG=${OUTPUT}/${PREFIX}_PlaScope/Centrifuge_results/centrifuge.log
echo Centrifuge log can be found here: ${CENTRIFUGE_LOG}
centrifuge -f --threads ${THREADS} -x ${DB_NAME} -U ${FASTA} -k 1 --report-file ${OUTPUT}/${PREFIX}_PlaScope/Centrifuge_results/${PREFIX}_summary -S ${OUTPUT}/${PREFIX}_PlaScope/Centrifuge_results/${PREFIX}_extendedresult &> ${CENTRIFUGE_LOG}

(( step++ ))

echo "Step $step: Extraction of plasmid, chromosome and unclassified predictions"

if [[ "$assembler" = 'unicycler' ]]; then
contig_sorting_unicycler ${OUTPUT}/${PREFIX}_PlaScope/Centrifuge_results/${PREFIX}_extendedresult > ${OUTPUT}/${PREFIX}_PlaScope/Centrifuge_results/${PREFIX}_list

elif [[ "$assembler" = 'spades' ]]; then
contig_sorting_spades ${OUTPUT}/${PREFIX}_PlaScope/Centrifuge_results/${PREFIX}_extendedresult > ${OUTPUT}/${PREFIX}_PlaScope/Centrifuge_results/${PREFIX}_list

else 
echo "Please provide a valid assembler: spades or unicycler" && exit 0
fi

contig_extraction ${FASTA} ${OUTPUT}/${PREFIX}_PlaScope/Centrifuge_results/${PREFIX}_list ${OUTPUT}/${PREFIX}_PlaScope/PlaScope_predictions/${PREFIX}

echo "If you use PlaScope please cite: ..."

exit 0

