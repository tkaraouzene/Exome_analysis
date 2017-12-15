#!/usr/bin/perl

# date: 18th october 2017
# author: Thomas Karaouzene

###########
#
# The goal of this script is to concatenate all fastq files 
# of a same patient sequenced on same strand (forward or revers)
# 
###########

use lib 'script';
use lib 'local_lib';

use warnings;
use strict;

use feature qw(say);
use Parallel::ForkManager;
use Getopt::Long;

use my_warnings qw(printq warnq dieq info_mess get_time error_mess warn_mess);
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
-p | --in_pattern                        # Input fastq file quoted pattern regexp  (name/lane/strand must be saved)
--out_pattern                            # Output file name pattern (default = grexome)
--fork [num_forks]                       # Use forking to improve script runtime (default = 1)
--verbose                                # Print out a bit more info while running
--quiet                                  # Print nothing to STDERR

--in_ext                                 # Input file extention (default = .fastq.gz) 
--out_ext                                # Output file extention (default = .fastq.gz) 
--exome_start                            # Force to start exome numerotation at this stage
--batch_start                            # Force to start batch numerotation at this stage

--test_pattern                           # Print name, strand and lane and die
--split_dir [n]                          # Split output fils into n dir
--config_only                            # Print config file and nothing else
--config_instrument                      # Used sequencer
--config_technology                      # Illumina, SoLID...
--config_platform                        # Sequencing center
--config_capture                         # Exome capture kit
--config_file_name                       # Name of output config file

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

my $seen_name = {};
my $config_fh;

## parse arguments
# store it in $config
my $config = &configure(scalar @ARGV);

# Return a very cute cat
warn &header() unless $config->{quiet}; 

# Retrun a string containing all args and its value 
warn &args_to_string($config) unless $config->{quiet};

## Prepare output directory
warnq info_mess."init out directorie..." unless $config->{quiet};
&init_outdir($config) or die;

## Retrieve input files:
#
# Browse --indir ad seek all files
# Return $fastq_table:
#   . $fastq_table->{$name}->{$strand} = [file1, ... , fileN]
#   . Where:
#       . $name = patient name
#       . $strand = sequencing lane 
#       . N is the nb of used lane to sequence $name
#
##
warnq info_mess."Seeking fastq files..." unless $config->{quiet};
my $fastq_table = &retrieve_input_files($config) or die;

## Find last exome nb
warnq info_mess."Seeking last exome nb in $config->{outdir}..." unless $config->{quiet};
&start_exome_nb($config) or die;

# start to zcat
warnq info_mess."Start to zcat files..." unless $config->{quiet};
warnq info_mess."$config->{fork} job(s) is(are) running" if $config->{verbose};

my $pm = new Parallel::ForkManager($config->{fork}); # job number
my @all_runs = sort(keys %$fastq_table);

## Init config file
unless ($config->{split_dir}) {

    $config_fh = &init_config($config) or die;

}

foreach my $run_index (0..$#all_runs) {
    
    $config->{run_index} = $run_index;

    my $run = $all_runs[$config->{run_index}];
    my $nb_r1_files = @{$fastq_table->{$run}->{1}};
    my $nb_r2_files = @{$fastq_table->{$run}->{2}};
    my $nb;

    if ($nb_r1_files != $nb_r2_files) {

	warnq warn_mess."$run: Different nb of files for R1 and R2, skiping it..."; 
	next;

    }

    &define_final_out_dir($config) or die;

    if ($seen_name->{$run}) {

    	$nb = $seen_name->{$run};
	
    } else {
	
    	# change exome nb
    	$nb = &format_exome_nb($config) or die;
	$config->{exome_id} = $config->{out_pattern}.$nb;
	$config->{id} = "P".$nb;
	$config->{fam} = "FAM".$nb;
	$config->{specimen} = $run;
    	print $config_fh &config_line($config) ;
	$config->{exome_nb}++;
    	$seen_name->{$run} = $nb;
    }

    unless ($config->{config_only}) {
	
    	$pm->start && next;

    	warnq info_mess."processing $run" if $config->{verbose};

    	foreach my $strand (sort(keys %{$fastq_table->{$run}})) {

    	    warnq info_mess."processing $run, strand $strand" if $config->{verbose};
	    $config->{strand} = $strand;
    	    my $cmd = &define_cmd($config) or next;	    
    	    `$cmd`;
    	}
	
    	warnq info_mess."$run done" if $config->{verbose};

    	$pm->finish;
    }
}

$pm->wait_all_children;

close $config_fh;

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
    	'help|h',                   # Print usage
    	'verbose|v',                # Print out a bit more info while running
	'fork=i',                   # Nb job
    	'quiet|q',                  # Print nothing to STDERR
    	'outdir|o=s',               # Output directory
	'indir|i=s',                # Input directory
	'split_dir=i',              # Split output fils into n dir

	'in_pattern|p=s',           # Input fastq file pattern regexp
	'in_ext=s',                 # Input file extention (default = .fastq.gz) 
	'out_pattern=s',            # Output file name pattern (default = grexome)
	'out_ext=s',                # Output file extention (default = .fastq.gz) 
	'exome_start=i',            # Force to start numerotation at this stage
	'batch_start=i',            # Force to start batch numerotation at this stage

	'test_pattern',             # Print name, strand and lane and die

	'config_only',              # print config file and nothing else
	'config_instrument=s',      # Used sequencer
	'config_technology=s',      # Illumina, SoLID...
	'config_platform=s',        # Sequencing center
	'config_capture=s',         # exome capture kit
	'config_file_name=s',       # name of output config file


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
    $config->{out_pattern} ||= "grexome";
    $config->{out_ext} = ".fastq.gz";
	

    $config->{config_file_name} ||= "my_config";

    # determine where to start batch directory numerotation
    $config->{batch_nb} = ($config->{batch_start}) ? --$config->{batch_start} : 0;

    return $config;
}

sub args_to_string {

    my $config = shift;
    my $cmd = "####\n## Settings:\n##\n";
    $cmd .= "## --$_ = $config->{$_}\n" foreach (sort(keys %$config));
    $cmd .= "##\n####\n\n";

    return $cmd;
}


sub init_outdir {

    my $config = shift;
    my $status = 1;
   
    unless(-d $config->{outdir}) {
	
	dieq error_mess."cannot mkdir $config->{outdir}: $!" unless mkdir($config->{outdir});
	warnq info_mess."mkdir $config->{outdir} done successfully" if $config->{verbose};
	
    } else {
	
	# todo check writting right here
	warnq info_mess."directory: $config->{outdir} already exists" if $config->{verbose};
    
    }

    return $status;
}

sub retrieve_input_files {
    
    ##
    #
    # 1. Browse --indir ad seek all files matching with 2 conditions:
    #    . End with --in_ext (basically .fastq.gz)
    #    . Contain --in_pattern (perl regexp)  
    #
    # 2. Parse file name according to --in_pattern
    #    . $1 = patient name
    #    . $2 = sequencing lane 
    #    . $3 = sequencing strand
    # 
    # 3. Fill $fastq_table:
    #    If $name has been sequenced on 1 lane: 
    #       . $fastq_table->{$name}->{$strand} = [file1]
    #    Else:
    #       . $fastq_table->{$name}->{$strand} = [file1, ... , fileN]
    #         Where N is the nb of used lane
    # 
    #  4. Return $fastq_table
    #
    # NB: If --test_pattern, this function will print name, lane and strand for each patient,
    #     In this case, $fastq_table is not filled
    #    
    ##

    my $config = shift;
    my $fastq_table;

    my $in_dh = openDIR($config->{indir});
    my $nb_files;

    while (my $in_file = readdir $in_dh) {
    
	next unless $in_file =~/$config->{in_ext}$/;
	next unless $in_file =~/$config->{in_pattern}/;

	$nb_files++;

	my $name = uc($1);
	my $lane = $2;
	my $strand = $3;

	if ($config->{test_pattern}) {

	    print "$in_file :: name = $name, lane = $lane, strand = $strand\n";


	} else {

	    push(@{$fastq_table->{$name}->{$strand}}, $config->{indir}."/".$in_file);
    
	}
    }

    closedir($in_dh);

    if ($nb_files) {
	
	warnq info_mess."$nb_files files matching with --pattern and --in_ext found in $config->{indir}"
	    if $config->{verbose};

    } else {
	
	warnq warn_mess."0 files matching with --pattern and --in_ext found in $config->{indir}"
	    unless $config->{quiet};
    }    

    return $fastq_table;
}

sub start_exome_nb {

    my $config = shift;
    my $out_dh = openDIR($config->{outdir});
    my $last_exome = 0;
    my $start_nb;
    my $status = 1;


    while (my $fastq_file = readdir $out_dh) {
    
	next unless $fastq_file =~/$config->{out_ext}$/;
    
	unless ($fastq_file =~ /^$config->{out_pattern}(\d+)\./) {
	    
	    warnq error_mess."unexpected fastq format: $fastq_file" unless $config->{quiet};
	    return;
	}

	my $exome_nb = $1;

	if ($exome_nb > $last_exome) {

	    $last_exome = $exome_nb;

	}
    }

    if ($config->{exome_start}) {
	
	if ($last_exome < $config->{exome_start}) {

	    $start_nb = $config->{exome_start};

	} else {

	    my $start = $last_exome + 1;
	    warnq error_mess."You cannot start exome numerotation before ".$start." change --exome_start parameter";
	    return;
	}
    
    } else {

	# exome nb start
	$start_nb = $last_exome + 1;
    }

    warnq info_mess."starting new serie from exome n°$start_nb" if $start_nb && $config->{verbose};
    
    $config->{exome_nb} = $start_nb;

    return $status;
}

sub format_exome_nb {

    my $config = shift;
    my $nb;
    
    if ($config->{exome_nb} >= 9999) {

        warnq error_mess."FIX ME!: nb exome > 999: you need to change your nomenclature";
	
    } elsif ($config->{exome_nb} < 10) {
	
	$nb = "000".$config->{exome_nb};
	
    } elsif ($config->{exome_nb} < 100) {
	
	$nb = "00".$config->{exome_nb};
    
    } elsif ($config->{exome_nb} < 1000) {

	$nb = "0".$config->{exome_nb};
    }

    return $nb;
}

sub init_config {


     my $config = shift;
     my $config_file;

     $config_file = $config->{outdir_final}."/".$config->{config_file_name};
     $config_file .= "_".$config->{batch_nb} if $config->{batch_nb};
     $config_file .= ".config";
     my $config_header = join("\t", "#patientID", "familyID", "motherID", "fatherID", "specimenID", 
			      "grexomeID", "instrument", "technology", "platform", "capture");
     
     my $config_fh = openOUT($config_file);
     
     print $config_fh $config_header."\n";
     
     $config->{config_fh} = $config_fh;

     return $config_fh;
}

sub config_line {

    my $config = shift;
    my $config_line;
    $config_line .= $config->{id};
    $config_line .= "\t".$config->{fam};
    $config_line .= "\t"."";
    $config_line .= "\t"."";
    $config_line .= "\t".$config->{specimen};
    $config_line .= "\t".$config->{exome_id};
    $config_line .= "\t".$config->{config_instrument};
    $config_line .= "\t".$config->{config_technology};
    $config_line .= "\t".$config->{config_platform};
    $config_line .= "\t".$config->{config_capture};
    $config_line .= "\n";    

    return $config_line;

}

sub define_final_out_dir {

    $config = shift;
    my $status = 1; 

    if ($config->{split_dir}) {
	
	if ($config->{run_index} % $config->{split_dir} == 0) {
	    $config->{batch_nb}++;
	    $config->{outdir_final} = $config->{outdir}."/batch_".$config->{batch_nb};

	    unless (-d $config->{outdir_final} || mkdir($config->{outdir_final})) {

		warnq error_mess."cannot mkdir $config->{outdir_final}: $!";
		$status = undef;
	    }

	    close $config_fh if $config_fh;
	    ## Init config file
	    $config_fh = &init_config($config) or $status = undef;

	} 
	
    } else {
	
	$config->{outdir_final} = $config->{outdir}
    }

    return $status;
}

sub define_cmd {
    
    my $config = shift;
    my $strand = $config->{strand};
    my $run = $config->{specimen};
    my $out_file = $config->{outdir_final}."/".$config->{exome_id}.".R".$strand.$config->{out_ext};;
    my $cmd;
    my @files = sort(@{$fastq_table->{$run}->{$strand}});

    if (@files == 1) {

	$cmd = "cp $files[0] $out_file";
    
    } elsif (@files == 2) {

	$cmd = "zcat @files | gzip -c >$out_file";

    } else {
	
	# for run having more than 1 files per strand per lane
	# skip then for the moment 
	# need to zcat them manually
	warnq warn_mess."More than 2 files for $config->{specimen}, skiping it...";

    }

    return $cmd;
}

sub header {
    
    #chomp(my $time = &get_time);
    my $logo =<<END;
 

  ##############
  #          ##  /\\     /\\       #----------------------#
            ##  {  `---'  }      #      zcat_fastq      #
           ##   {  O   O  }      #----------------------# 
          ##  ~~|~   V   ~|~~    
         ##      \\  \\|/  /   
        ##        `-----'__
       ##         /     \\  `^\\_
      ##         {       }\\ |\\_\\_   W
     ##          |  \\_/  |/ /  \\_\\_( )
    ##            \\__/  /(_E     \\__/
   ##               (  /
  ##           #     MM
 ###############


END
    return $logo;
}

1;
