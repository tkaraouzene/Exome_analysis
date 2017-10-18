#!/usr/bin/perl

# date: 18th october 2017
# author: Thomas Karaouzene

###########
#
# Ce script va chercher l'ensemble des fichiers ayant l'extention .fastq.gz.
# Ensuite, il va effectuer un zcat sur les fichiers d'un même atient (et même strand) 
# mais ayant été séquencés sur différentes lanes.
# Les patterns des fichiers d'input et d'output sont à préciser dans SETTINGS.
# 
###########

use lib 'script';

use warnings;
use strict;

use feature qw(say);
use Parallel::ForkManager;
use Getopt::Long;

use my_warnings qw(printq warnq dieq info_mess error_mess warn_mess);
use my_file_manager qw(openDIR openIN openOUT close_files);


sub usage {
    
    my $usage =<<END;

Usage:
    perl zcat_fastq.pl [arguments]

Basic options
=============

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


Info : --indir has to be mentionned
       --fork default = 1

END
return $usage;

}

###########
#
# MAIN
#
###########

my $config = &configure(scalar @ARGV);
my $fastq_table = {};
## Retrieve fastq files
# Store it in a hash table: 
# $fastq_files->{fastq_start}->[$strand] = (file1, file2)

warnq info_mess."Seeking fastq files..." unless $config->{quiet};

my $in_dh = openDIR($config->{indir});

while (my $in_file = readdir $in_dh) {
    

    next unless $in_file =~/$config->{in_ext}$/;
    next unless $in_file =~/$config->{in_pattern}/;

    my $name = $1;
    my $lane = $2;
    my $strand = $3;

    push(@{$fastq_table->{$name."_".$strand}}, $config->{indir}."/".$in_file);
}

closedir($in_dh);

# Prepare output directory
unless(-d $config->{outdir}) {

    dieq error_mess."cannot mkdir $config->{outdir}: $!" unless mkdir($config->{outdir});
    warnq info_mess."mkdir $config->{outdir} done successfully";
}


# find last exome nb
warnq info_mess."Seeking last exome nb in $config->{outdir}..." unless $config->{quiet};

my $out_dh = openDIR($config->{outdir});
my $last_exome = 0;

while (my $fastq_file = readdir $out_dh) {
    
    next unless $fastq_file =~/$config->{out_ext}$/;
    
    dieq error_mess."unexpected fastq format: $fastq_file" unless $fastq_file =~ /^$config->{out_pattern}(\d+)\./;

    my $exome_nb = $1;

    if ($exome_nb > $last_exome) {

	$last_exome = $exome_nb;

    }
}

# exome nb start
my $i = $last_exome + 1;

# start to zcat
warnq info_mess."Start to zcat files..." unless $config->{quiet};
warnq info_mess."$config->{fork} job(s) is(are) running" if $config->{verbose};

my $pm = new Parallel::ForkManager($config->{fork}); # job number

foreach my $run (sort(keys %$fastq_table)) {

    dieq error_mess."unexpected run format: $run" unless $run =~ /^(.+)_(\d)$/;

    my $name = $1;
    my $strand = $2;
    
    # change exome nb
    my $nb = &exome_nb($i) or die;

    my $out_file = $config->{outdir}."/".$config->{out_pattern}.$nb.".R".$strand.".".$config->{out_ext};
    my $cmd = "zcat @{$fastq_table->{$run}} | gzip -c > $out_file";
    $i++;
    $pm->start && next;
    
    `$cmd`;
    
    $pm->finish;
}

$pm->wait_all_children;

warnq info_mess."All done" unless $config->{quiet};



###########
#
# SUB
#
###########


sub configure {

    my $args = shift;    
    my $config = {};

    GetOptions(
        $config,
    	'help|h',                   # print usage
    	'verbose|v',                # print out a bit more info while running
    	'quiet|q',                  # print nothing to STDERR
    	'outdir|o=s',               # output directory
	'indir|i=s',                # input directory
	'in_pattern|p=s',           # input fastq file pattern regexp
	'in_ext=s',                 # input file extention (default = .fastq.gz) 
	'out_pattern=s',            # output file name pattern (default = grex)
	'out_ext=s',                # output file extention (default = .fastq.gz) 

    	) or dieq error_mess."unexpected options, type -h or --help for help";


    if((defined $config->{help}) || !$args) {
	print &usage;
	die;
    }

    # # if(defined $config->{help}) {
    # # 	print &completUsage;
    # # 	die;
    # # }
    
    # check of brain sanity
    dieq error_mess."cannot be both quiet and verbose!" if $config->{verbose} && $config->{quiet};
    
    # check in directory:
    dieq error_mess."--indir has to be mentioned" unless $config->{indir};
    dieq error_mess."--indir $config->{indir} has to exist" unless -d $config->{indir};

    # check out directory:
    $config->{outdir} ||= "fastq";

    unless(-d $config->{outdir}) {

    	dieq error_mess."cannot mkdir $config->{outdir}: $!" unless mkdir($config->{outdir});
    	warnq info_mess."mkdir $config->{outdir} done successfully" if $config->{verbose}
    }
    
    # check forking: 
    $config->{fork} = 1 unless $config->{fork};
    dieq error_mess."fork must be a number" if $config->{fork} =~ /^\D+$/;
    dieq error_mess."fork number must be greater than 0" if $config->{fork} <= 0;
    
    # in files property
    dieq error_mess."--in_pattern has to be mentioned" unless $config->{in_pattern};
    $config->{in_ext} ||= ".fastq.gz";

    # out files property
    $config->{out_pattern} ||= "grex";
    $config->{out_ext} = ".fastq.gz";
	
    return $config;
}









sub exome_nb {

    my $i = shift;
    my $nb;
    
    if ($i >= 9999) {

        warnq error_mess."FIX ME!: nb exome > 999: you need to change your nomenclature";
	
    } elsif ($i < 10) {
	
	$nb = "000".$i;
	
    } elsif ($i < 100) {
	
	$nb = "00".$i;
    
    } elsif ($i < 1000) {

	$nb = "0".$i;
    }

    return $nb;
}



1;
