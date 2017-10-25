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

TO update

#### Usage:

```perl    
perl zcat_fastq.pl [arguments]
```

#### Options: 

```perl

--help                                   # Display complet usage and quit 
-o | --outdir [dir]                      # Output directory (default = fastq)
-i | --indir [dir]                       # Directory containing input VCF files 
-p | --in_pattern                        # input fastq file quoted pattern regexp  (name/lane/strand must be saved)
--out_pattern                            # output file name pattern (default = grex)
--fork [num_forks]                       # Use forking to improve script runtime (default = 1)
--verbose                                # print out a bit more info while running
--quiet                                  # print nothing to STDERR

--in_ext                                 # input file extention (default = .fastq.gz) 
--out_pattern                            # output file name pattern (default = grex)
--out_ext                                # output file extention (default = .fastq.gz) 
--exome_start                            # force to start numerotation at this stage
--test_pattern                           # Print name, strand and lane and die

Info : --indir has to be mentionned
       --fork default = 1
```

#### Used settings:


##### Novogene 2017:

```bash
--in_pattern "P([^_]+).+_L(\d)_(\d)" 
--in_ext .fq.gz
```


## Directory:

### script:
