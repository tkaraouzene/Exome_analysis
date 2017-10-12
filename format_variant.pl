#!/usr/bin/perl

# date: 12th october 2017
# author: Thomas Karaouzene

###########
#
# The goal of this script is to format vcf files to a friendly readable 
# csv files
# 
###########


###########
#
# TODO:
#
###########
#
# Un code mieux commenté
# un version plus robuste de findAnnot
# possibilité de créer un fichier / patient / chromosome
#
###########

use lib 'script';

use warnings;
use strict;

use feature qw(say);
use Parallel::ForkManager;
use Getopt::Long;

use my_vcf_functions qw(fill_vcf_format skip_vcf_meta parse_vcf_line parse_vcf_info);
use my_vep_functions qw(parse_vep_info parse_vep_meta_line fill_vep_table);
use my_file_manager qw(openDIR openIN openOUT close_files);
use my_warnings qw(printq warnq dieq info_mess error_mess warn_mess);

sub usage {
    
    my $usage =<<END;

Usage:
    perl format_variant.pl [arguments]

Basic options
=============

--help                                   # Display complet usage and quit 
-o | --outdir [dir]                      # Output directory 
-i | --indir [dir]                       # Directory containing input VCF files 
--vep [VEP key]                          # default = "CSQ"
--annot [annot1,annot2,...,annotN]       # list of kept VEP annotation (default = all) 
--fork [num_forks]                       # Use forking to improve script runtime (default = 1)

Info : --indir has to be mentionned
       --outdir default = VCF/ (created if doesn\'t exist)
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

my @in_files = ();
my @out_files = ();
my @err_files = ();


# Retrieve vcf in files (all vcf files within $config->{indir})
# Define all vcf out files 

warnq info_mess."Seeking files to format..." unless $config->{quiet};

my $vcf_dh = openDIR($config->{indir});

while (my $in_file = readdir $vcf_dh) {
    
    next unless $in_file =~ /$config->{vcf_ext}$/;

    (my $out_file = $in_file) =~ s/$config->{vcf_ext}$/_$config->{out_tail}\.csv/;
    (my $err_file = $in_file) =~ s/$config->{vcf_ext}$/_$config->{out_tail}\.err/;

    push(@in_files, $config->{indir}."/".$in_file);
    push(@out_files, $config->{outdir}."/".$out_file);
    push(@err_files, $config->{error}."/".$err_file);

}

closedir $vcf_dh;

dieq error_mess."FIX ME!: \@in_files, \@out_files and \@err_files should containes the same nb of element" unless
    (@in_files == @out_files) && (@in_files == @err_files);

warnq info_mess.scalar(@in_files)." vcf files found" if $config->{verbose};

# ###

warnq info_mess."Formating files..." unless $config->{quiet};

my $pm = new Parallel::ForkManager($config->{fork}); # job number
warnq info_mess."$config->{fork} job(s) is(are) running" unless $config->{quiet};

foreach my $index (0..$#in_files) {

    $pm->start && next;

    my $in_file = $in_files[$index];
    my $out_file = $out_files[$index];

    warnq info_mess."Formating file: ".$in_file." (".($index + 1)."/".scalar(@in_files).")";
    my $n_line = 1;
    my @first_format;

    my $in_fh = openIN($in_file);
    my $out_fh = openOUT($out_file);

    my ($meta, $vcf_header, $vep_meta) = skip_vcf_meta($in_fh, $config->{vep});
    my $vep_format = parse_vep_meta_line($vep_meta);

    while (<$in_fh>) {

	##################
	# 
	# 0: chromosome (ex: 11)
	# 1: Position: variant position (ex: 209898)
	# 2: variant ID
	# 3: Reference allele
	# 4: Variation allele
	# 5: Quality
	# 6: Filter 
	# 7: Info
	# 8: Format
	# 9: Others
	# 
	##################
	my ($chr,$pos,$rs,$ref,$alt,$info,$format,$other) = parse_vcf_line($_, 0..4, 7..9);
	my $info_table = parse_vcf_info($info);

	my $format_table = fill_vcf_format($format, $other);
	my $vep_info = &findAnnot($info_table, $config->{vep});
	my $vep_infos = parse_vep_info($vep_info);
	
	my @format = sort(keys(%$format_table));
	my @value = ();

	# print header line
	if ($n_line == 1) {
	    
	    say $out_fh join("\t", "CHR", "POSITION", "REF", "ALT", @{$config->{annot}}, @format);
	    @first_format = @format
	
	} 
	
	#
	foreach my $f (@first_format) {

	    my $v = $format_table->{$f} || ".";
	    push(@value, $v);
	}

	$n_line++;

	foreach my $vi (@$vep_infos) {

	    # return a hash table with key 
	    my $vep_table = fill_vep_table($vi, $vep_format);	 
	    my @vep_annot = &findAnnot($vep_table, @{$config->{annot}});
	    
	    say $out_fh join("\t", $chr, $pos, $ref, $alt, @vep_annot, @value);
	}
    }

    close_files($in_fh, $out_fh);

    $pm->finish;

}

$pm->wait_all_children;

warnq info_mess."All done";

###########
#
# SUB
#
###########

sub findAnnot {

    my $table = shift;    
    my @annot_to_return = (@_) ? 
	(@_) : 
	(sort(keys %$table)); # return all value having a key within the table if nothing is ask
    my @r;

    push @r, $table->{$_} || "" foreach @annot_to_return; # value = "" if key is missing 
    
    warnq warn_mess."Nothing found" if @r == 0;

    (@r == 1) ? 
	(return $r[0]) :
	(return @r);
}



sub configure {

    my $args = shift;    
    my $config = {};

    GetOptions(
        $config,
    	'help|h',                   # print usage
    	'verbose|v',                # print out a bit more info while running
    	'quiet|q',                  # print nothing to STDERR
    	'outdir|o=s',               # output directory
    	'indir|i=s',                  # output directory
	'annot=s',                    # list of kept VEP annotation (default = all)
	'vep=s',                      # variant_effect_predictor vcf key (default = "CSQ")

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
    dieq error_mess."--indir has to be mentioned" unless defined $config->{indir};
    dieq error_mess."--indir $config->{indir} has to exist" unless -d $config->{indir};

    # check out directory:
    $config->{outdir} ||= "VCF";

    unless(-d $config->{outdir}) {

    	dieq error_mess."cannot mkdir $config->{outdir}: $!" unless mkdir($config->{outdir});
    	warnq info_mess."mkdir $config->{outdir} done successfully" if $config->{verbose}
    }
    
    # check error dir:
    $config->{errordir} ||= $config->{outdir}."/error";
    dieq error_mess."Cannot mkdir $config->{errordir}: $!" unless -d $config->{errordir} || mkdir $config->{errordir};

    # check forking: 
    $config->{fork} = 1 unless $config->{fork};
    dieq error_mess."fork must be a number" if $config->{fork} =~ /^\D+$/;
    dieq error_mess."fork number must be greater than 0" if $config->{fork} <= 0;
    
    # check vep VCF key 
    $config->{fork} ||= 1;

    # check vep kept annotation
    my $annot = [];

    if ($config->{annot}) {
	
	my $annot = [split(/,/, $config->{annot})];
	$config->{annot} = $annot;

    } else {

	$config->{annot} = $annot;
    }

    # out files property
    $config->{out_tail} = "format";

    # out files property
    $config->{vcf_ext} = ".vcf";

    return $config;
}


1;
