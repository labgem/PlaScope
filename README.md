<p align="center"><img src="/PlaScope_supernova.png" width="50%"></p>

# PlaScope


A targeted approach to assess the plasmidome of bacteria.

If you use our approach, please cite :

## Tell me more about PlaScope


This method enables you to classify contigs from a WGS assembly according to their location (i.e. plasmid or chromosome). It is based on a smart tool called Centrifuge (https://github.com/infphilo/centrifuge), initially developped as a metagenomic classifier.
We proposed here an application on *E. coli* plasmidome, with a specific database build on one hand on completely finished genomes of *E. coli* from the NCBI, and on the other hand on a custom plasmid database. In fact 3 database of plasmid have been merged together : plasmids used to create plasmidfinder (http://aac.asm.org/content/58/7/3895.long), plasmids proposed by Orlek *et al.* (https://www.sciencedirect.com/science/article/pii/S2352340917301567?via%3Dihub) and plasmids from the ColiScope project ()

However we think that this method can easily be applied to other bacterial species since you have got enough reference data.


## Dependencies


SPAdes 3.10.1 or later to run the assembly (header of contigs must be the same as in version 3.10.1) (http://bioinf.spbau.ru/spades)

Centrifuge 1.0.3 (https://github.com/infphilo/centrifuge)

GNU awk (https://www.gnu.org/software/gawk/manual/gawk.html)

Pyfasta (https://github.com/brentp/pyfasta)


## Building Centrifuge Database 
(for more information on custom DB please refer to http://www.ccb.jhu.edu/software/centrifuge/)


The trick of our method is to build a custom database for Centrifuge with an artificial taxonomy containing only 3 nodes (see seqid_to_taxid.map, nodes.dmp and names.dmp files)
```
centrifuge-build -p 10 --conversion-table seqid_to_taxid.map --taxonomy-tree nodes.dmp --name-table names.dmp database.fna chromosome_plasmid_db
```

## Classification of contigs according to their location

First you need to assemble your genome with SPAdes :
```
spades.py --careful -1 forward_read -2 reverse_read -o output_directory
```

Then run the classification with "-k 1" to get only one assignation for your contigs :
```
centrifuge -f --threads 2 -x chromosome_plasmid_db -U your_genome.fasta -k 1 --report-file your_genome_summary.txt -S your_genome_extendedresult.txt
```

Parse the results :
```awk
awk -F'\t' '$3==3 && $7>=500 && $6>=100 {print $1}' your_genome_extendedresult.txt | awk -F'_' '$6>=2 {print $0}' > plasmid_list
awk -F'\t' '$3==2 && $7>=500 && $6>=100 {print $1}' your_genome_extendedresult.txt | awk -F'_' '$6>=2 {print $0}' > chromsome_list
awk -F'\t' '$3==1 && $7>=500 && $6>=100 {print $1}' your_genome_extendedresult.txt | awk -F'_' '$6>=2 {print $0}' > unknown_list
```

Finally create fasta file according to the prediction :
```
pyfasta extract --header --fasta your_genome.fasta --file plasmid_list > your_genome_plasmid.fasta
pyfasta extract --header --fasta your_genome.fasta --file chromosome_list > your_genome_chromosome.fasta
pyfasta extract --header --fasta your_genome.fasta --file unknown_list > your_genome_unknown.fasta
```

## Composition of the database

See Reference_chromosome.tab for the list of *E. coli* chromosome used in our exemple
See Reference_plasmid.tab for the list of plasmids and their related database.

## Create your own database

You can also design your own database as explained On Centrifuge website https://ccb.jhu.edu/software/centrifuge/manual.shtml#custom-database.

You need to prepare two files, as described below :

