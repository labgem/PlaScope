<p align="center"><img src="PlaScope_supernova.png" width="50%"></p>

# PlaScope


A targeted approach to assess the plasmidome of bacteria.

If you use this tool, please cite : G. Royer, J.-W. Decousser, C. Branger, M. Dubois, C. Médigue, E. Denamur, D. Vallenet. PlaScope: a
targeted approach to assess the plasmidome from genome assemblies at species level. Microbial
Genomics, 2018 Sep;4(9).

And don't forget the publications related to its dependencies : 
- Bankevich A, Nurk S, Antipov D, Gurevich AA, Dvorkin M et al. SPAdes: a new genome assembly algorithm and its applications to single-cell sequencing. J Comput Biol 2012;19:455–477
- Kim D, Song L, Breitwieser FP, Salzberg SL. Centrifuge: rapid and sensitive classification of metagenomic sequences. Genome Res
2016;26:1721–1729


## Tell me more about PlaScope


This method enables you to classify contigs from a WGS assembly according to their location (i.e. plasmid or chromosome). It is based on a smart tool called [Centrifuge](https://www.ccb.jhu.edu/software/centrifuge/), initially developed as a metagenomic classifier.
We propose here an application on *E. coli* plasmidome, with a specific database build on one hand on completely finished genomes of *E. coli* from the NCBI, and on the other hand on a custom plasmid database. In fact 3 databases of plasmid have been merged together :

* plasmids used to create plasmidfinder (http://aac.asm.org/content/58/7/3895.long)
* plasmids proposed by Orlek *et al.* (https://www.sciencedirect.com/science/article/pii/S2352340917301567?via%3Dihub)
* plasmids from Branger *et al.*, Extended-spectrum ß-lactamase-genes are spreading on a wide range of Escherichia coli plasmids existing prior the use of third generation cephalosporins, Microbial Genomics, 2018, In press

We also propose a Klebsiella database that has been evaluated on a clinical dataset of 12 *Klebsiella pneumoniae* strains.

We think that this method can easily be applied to other bacterial species since you have got enough reference data (e.g. *Staphylococcus aureus*, *Enterococcus sp.* ...).

## Installation

### Dependencies

You must install these dependencies before you start :

* [SPAdes](http://bioinf.spbau.ru/spades) 3.10.1 or later if you want to run the assembly (= mode 1) (header of contigs must be the same as in version 3.10.1, *e.g* >NODE_1_length_506801_cov_117.065)
* [Centrifuge](https://www.ccb.jhu.edu/software/centrifuge/) 1.0.3

### Installation

`PlaScope` is essentially a wrapper script (called `plaScope.sh`) around SPAdes and Centrifuge.
It's written in `bash` and `awk` and should work on Linux and Mac OS X both with GNU awk and BSD awk.

To install it, simply download the sources and decompress them.
Don't forget to add the location of `plaScope.sh` to your `PATH`.

### Installation with BioConda

The easiest way to install `PlaScope` and its dependencies is through [BioConda](https://bioconda.github.io/).
Once you have created and activated a `conda` environment, simply type:

```bash
$ conda install plascope
```

Note that several versions of `awk` are available in `conda` so you can further control the environment.

### Usage with the IFB Cloud

Another way to use `PlaScope` is through the [IFB Cloud](https://biosphere.france-bioinformatique.fr/).
Just create an account and launch the [PlaScope](https://biosphere.france-bioinformatique.fr/catalogue/appliance/155/) appliance.

## Usage

You can choose between two modes:
* Mode 1: SPAdes assembly then contig classification
* Mode 2: contig classification only (if you already assembled your genome with SPAdes)

```bash
$ ./plaScope.sh -h
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


Mode 2: contig classification of a fasta file (only if you already have your SPAdes assembly!)
  --fasta		SPAdes assembly fasta file [MANDATORY]



Example mode 1:
plaScope.sh -1 my_reads_1.fastq.gz -2 my_reads_2.fastq.gz -o output_directory  --db_dir path/to/DB --db_name chromosome_plasmid_db --sample name_of_my_sample

Example mode 2:
plaScope.sh --fasta my_fastafile.fasta -o output_directory --db_dir path/to/DB --db_name chromosome_plasmid_db --sample name_of_my_sample



Github:
https://github.com/GuilhemRoyer/PlaScope
````

`PlaScope` uses a database (see [this section](#DB)) made of 3 files.
The argument `--db_dir` is the path to the directory where these 3 files are located.
The argument `--db_name` is the common part between the file names (see examples).


## <a name="DB">Databases</a>

### *E. coli* database

To get the *E. coli* database, please download the following file on Zenodo: https://doi.org/10.5281/zenodo.1311641

After extracting the tar.gz file, you will have 3 files : `chromosome_plasmid_db.1.cf`, `chromosome_plasmid_db.2.cf` and `chromosome_plasmid_db.3.cf`. All these files are required for `PlaScope`.
In this case, the `--db_name` to use is "chromosome_plasmid_db".


### Klebsiella database

To get the Klebsiella database, please download the following file on Zenodo: https://doi.org/10.5281/zenodo.1311647

After extracting the tar.gz file, you will have 3 files : `Klebsiella_PlaScope.1.cf`, `Klebsiella_PlaScope.2.cf` and `Klebsiella_PlaScope.3.cf`. All these files are required for `PlaScope`.
In this case, the `--db_name` to use is "Klebsiella_PlaScope".

This database has not been extensively benchmarked. We only have assessed its performances by searching for plasmids and resistance genes location on a set of 12 *Klebsiella pneumoniae* strains from https://academic.oup.com/jac/article/73/7/1796/4966148.

### Create your own database

You can also design your own database as explained on [this page](https://ccb.jhu.edu/software/centrifuge/manual.shtml#custom-database).

You need to prepare four files:

* database.fna : a multifasta file of your database
```
>Chromosome_1
ATGGATAAGTTGCTGAACAAAAAGAT......
>Chromosome_2
GAGTGAACGGATGAAACAGAAAGACC......
>Plasmid_1
TCTCGAATGATAAAGGCTATGATGGC......
```

* nodes.dmp : an artificial taxonomy (*i.e.* root, chromosome, plasmid)
```
1 | 1 |	root
2 | 1 | chromosome
3 | 1 | plasmid
```

* seqid_to_taxid.map : a mapping file between the sequences and their taxonomic assignment
```
Chromosome_1  2
Chromosome_2  2
Plasmid_1 3
```

* names.dmp : a file mapping taxonomy IDs to a name
```
1	|	root	|   |   |
2	|	chromosome  |   |   |
3	|	plasmide  |   |   |
```
Then, build your database as follow:

```
centrifuge-build -p 10 --conversion-table seqid_to_taxid.map --taxonomy-tree nodes.dmp --name-table names.dmp database.fna chromosome_plasmid_db
```
