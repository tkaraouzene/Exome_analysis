# Exome_analysis


## 

### format_variant.pl


The goal of this script is to format vcf files to a friendly readable csv files

Usage:
    perl format_variant.pl [arguments]

Options
=============

```perl
--help                                   # Display complet usage and quit 
-o | --outdir [dir]                      # Output directory (created is doesn't exist)
-i | --indir [dir]                       # Directory containing input VCF files 
-e | --errordir [dir]                    # Directory containing error files (default = outdir/error, 
                                                                            created is doesn't exist)
--vep [VEP key]                          # default = "CSQ"
--annot [annot1,annot2,...,annotN]       # list of kept VEP annotation (default = all) 
--fork [num_forks]                       # Use forking to improve script runtime (default = 1)
--verbose                                # print out a bit more info while running
--quiet                                  # Shhhhhhh !!!

Info : --indir has to be mentionned
       --outdir default = VCF/ (created if doesn\'t exist)
       --fork default = 1
```



