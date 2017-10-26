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

Info : --indir has to be mentionned
       --fork default = 1
```

#### Used settings:


##### Novogene 2017:


25/10/2017: 20h41

###### CMD:

on luke server:

```bash
pwd
```

```bash
/home/karaout/analyses
```
---

```bash

oarsub -l /nodes=1/core=12,walltime=06:00:00 --project dnaseq_wes \
       "perl zcat_fastq.pl -i input_novogene_2017 \
      		    -o demultiplex_novogene_2017 \
		    -p \"P([^_]+).+_L(\d)_(\d)\" \
		    --in_ext .fq.gz \
		    --verbose \
		    --exome_start 50 \
		    --split_dir 12 \
		    --fork 12 \
		    --config_instrument HiseqX \
		    --config_technology Illumina \
		    --config_platform Novogene \
		    --config_capture Agilent_v6 \
		    --config_file_name novogene_2017 \
		    2>demultiplex_novogene_2017/171015_zcat_fastq.log"
```


###### NOTE

```bash
ls -l --b=M  OAR.3635802.std* | cut -d " " -f5
```

```bash 
0M
0M
```

Ok OAR.3635802.stderr and OAR.3635802.stdout are empty, good thing

---

```bash
grep ERROR demultiplex_novogene_2017/171015_zcat_fastq.log
```
```bash

```

No error, good...

---

```bash
grep WARNING demultiplex_novogene_2017/171015_zcat_fastq.log
```

```
2017-10-25 20:48:32 - WARNING!: (main::define_cmd): More than 2 files for 12IF017, skiping it...
2017-10-25 20:48:32 - WARNING!: (main::define_cmd): More than 2 files for 12IF017, skiping it...
2017-10-25 21:36:22 - WARNING!: (main::define_cmd): More than 2 files for 15IF051, skiping it...
2017-10-25 21:36:22 - WARNING!: (main::define_cmd): More than 2 files for 15IF051, skiping it...
```

Ok, like I knew, their are more than one files perl strand per lane for these two run,
I need to launch it manually...













## Directory:

### script:
