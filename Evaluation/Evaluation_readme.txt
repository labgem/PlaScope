The script evaluation.sh is used to compare prediction results from PlaScope, Plasflow and cBar for a given genome. It calculates recall, specificity, precision, accuracy and F1-score.

Quast v4.5 is required to run the evaluation as well as filter_spades.py script (writted by David Powell, available here: https://github.com/drpowell/utils/blob/master/filter-spades.pys.py)

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
  
  example:
  
  evaluation.sh -o my_evaluation --sample GCA_002011945 --ref_plasmids GCA_002011945.1_all_plasmids.fasta --ref_chromosome NZ_CP018948.1.fasta --fasta GCA_002012045.1.fasta --plascope_res GCA_002012045.1_list --plasflow_plasmid GCA_002012045.1_plasflow_plasmids.fasta --plasflow_chr GCA_002012045.1_plasflow_chromosomes.fasta --plasflow_uc GCA_002012045.1_plasflow_unclassified.fasta --cBar res GCA_002012045.1_cBar.txt
