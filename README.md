# Exome_analysis

## Files

### format_variant.pl: 

#### Description:

The goal of this script is to format vcf files to a friendly readable csv files.
INFO field is parsed to find variant_effect_predictor (VEP) annotation (default: CSQ=.....).
It is possible to choose which VEP annotation you want to keep with --annot (default is all).

#### Usage:

```perl    
perl format_variant.pl [arguments]
```
#### Options:

```perl
--help                                   # Display complet usage and quit 
-o | --outdir [dir]                      # Output directory (created is doesn't exist)
-i | --indir [dir]                       # Directory containing input VCF files 
-e | --errordir [dir]                    # Directory containing error files (default = outdir/error, 
                                         #                                  created is doesn't exist)
--vep [VEP key]                          # (Default = "CSQ")
--annot [annot1,annot2,...,annotN]       # list of kept VEP annotation (default = all) 
--fork [num_forks]                       # Use forking to improve script runtime (default = 1)
--verbose                                # Print out a bit more info while running
--quiet                                  # Shhhhhhh !!!
--gzip_out                               # compress output files (IO::Compress::Gzip must be installed)

Info : --indir has to be mentionned
       --outdir default = VCF/ (created if doesn\'t exist)
       --fork default = 1
```



### zcat_fastq.pl: 


#### Description:

Ce script va chercher l'ensemble des fichiers ayant l'extention .fastq.gz.
Ensuite, il va effectuer un zcat sur les fichiers d'un même atient (et même strand) 
mais ayant été séquencés sur différentes lanes.
Les patterns des fichiers d'input et d'output sont à préciser dans SETTINGS.

#### Usage:

Avant de lancer le programme il est conseillé de l'éditer pour modifier les paramètres (dans SETTINGS) propores à l'analyse.

## Directory:

### script:
