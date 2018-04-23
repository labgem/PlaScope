<p align="center"><img src="/PlaScope_supernova.png" width="50%"></p>

# PlaScope


A targeted approach to assess the plasmidome of bacteria.

If you use our approach, please cite :

## Tell me more about PlaScope


This method enables you to classify contigs from a WGS assembly according to their location (i.e. plasmid or chromosome). It is based on a smart tool called Centrifuge (https://github.com/infphilo/centrifuge), initially developped as a metagenomic classifier.
We proposed here an application on *E. coli* plasmidome, with a specific database build on one hand on completely finished genomes of *E. coli* from the NCBI, and on the other hand on a custom plasmid database. In fact 3 databases of plasmid have been merged together : plasmids used to create plasmidfinder (http://aac.asm.org/content/58/7/3895.long), plasmids proposed by Orlek *et al.* (https://www.sciencedirect.com/science/article/pii/S2352340917301567?via%3Dihub) and plasmids from the ColiScope project ()

However we think that this method can easily be applied to other bacterial species since you have got enough reference data.


## Dependencies

You must install these dependencies before you start :

SPAdes 3.10.1 or later to run the assembly (header of contigs must be the same as in version 3.10.1) (http://bioinf.spbau.ru/spades)

Centrifuge 1.0.3 (https://github.com/infphilo/centrifuge)

GNU awk (https://www.gnu.org/software/gawk/manual/gawk.html)

Pyfasta (https://github.com/brentp/pyfasta)


## Classification of contigs according to their location

```
./PlaScope.sh -h

usage: PlaScope.sh [OPTIONS] [ARGUMENTS]

-h, --help		display this message
-t			number of threads[OPTIONAL] [default : 8] 
-i			fastq name (assumed to be filename_1.fastq.gz / filename_2.fastq.gz) [MANDATORY]
--fastq_dir		path to fastq directory [MANDATORY]
-o			output directory [OPTIONAL] [default : current directory]
--db_dir		path to centrifuge database [MANDATORY]
--db_name		centrifuge database name [MANDATORY]

Wrapper to launch PlaScope (SPAdes + Centrifuge-based plasmidic sequences classification)
````

## Composition of the *E. coli* database

See Reference_chromosome.tab for the list of *E. coli* chromosome used in our exemple
See Reference_plasmid.tab for the list of plasmids and their related database.

## Create your own database

You can also design your own database as explained On Centrifuge website https://ccb.jhu.edu/software/centrifuge/manual.shtml#custom-database.

You need to prepare four files files:

-database.fna : a multifasta file of your database  
-nodes.dmp : an artificial taxonomy (*i.e.* root, chromosome, plasmid)  
-seqid_to_taxid.map : a mapping file between the sequences and their taxonomic assignment  
-names.dmp : a file mapping taxonomy IDs to a name  

Then, build your database as follow:

```
centrifuge-build -p 10 --conversion-table seqid_to_taxid.map --taxonomy-tree nodes.dmp --name-table names.dmp database.fna chromosome_plasmid_db
```
