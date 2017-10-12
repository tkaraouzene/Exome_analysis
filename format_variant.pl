#!/usr/bin/perl

use lib 'script';

use warnings;
use strict;

use feature qw(say);
use Parallel::ForkManager;
use Getopt::Long;

# use my_vcf_functions qw(skip_vcf_meta parse_vcf_line parse_vcf_info);
# use my_vep_functions qw(parse_vep_info parse_vep_meta_line fill_vep_table);
# use my_file_manager qw(openDIR openIN openOUT close_files);
# use my_warnings qw(printq warnq dieq info_mess error_mess warn_mess);

#######
#
# The goal of this script is to format vcf files to a friendly readable 
# csv files
# 
#######


sub usage {
    
    my $usage =<<END;

Usage:
    perl format_variant.pl [arguments]

Basic options
=============

--help                           # Display complet usage and quit 
-o | --outdir [dir]              # Output directory 
-i | --indir [dir]        # Directory containing input VCF files 
--fork [num_forks]               # Use forking to improve script runtime (default = 1)

Info : --indir has to be mentionned
       --outdir default = VCF/ (created if doesn\'t exist)
       --fork default = 1

END
return $usage;

}









# ################
# #
# # SETTINGS
# #
# ################

# # If you want to run this script you probably need to 
# # adjust parameters bellow.

# my $nb_job = 18;

# my $vep_key = "CSQ";
# my @kept_vep_annot = ();
# my $vcf_dir = "VCF/ANNOTATED";
# my $out_dir = "FORMATED";
# my $vcf_extention = ".vcf"; 
# my $out_extention = "format";

# ################
# #
# # INIT
# #
# ################

# my @in_files = ();
# my @out_files = ();
# my @err_files = ();
# my $error_dir = $out_dir."/error";

# dieq error_mess."Cannot mkdir $out_dir: $!" unless -d $out_dir || mkdir $out_dir;
# dieq error_mess."Cannot mkdir $error_dir: $!" unless -d $error_dir || mkdir $error_dir;

# ################
# #
# # MAIN
# #
# ################

# # Retrieve vcf in files (all vcf files within $vcf_dir)
# # Define all vcf out files 
# warnq info_mess."Seeking files to format:";

# my $vcf_dh = openDIR($vcf_dir);

# while (my $in_file = readdir $vcf_dh) {
    
#     next unless $in_file =~ /$vcf_extention$/;

#     (my $out_file = $in_file) =~ s/$vcf_extention$/_$out_extention\.csv/;
#     (my $err_file = $in_file) =~ s/$vcf_extention$/_$out_extention\.err/;

#     push(@in_files, $vcf_dir."/".$in_file);
#     push(@out_files, $out_dir."/".$out_file);
#     push(@err_files, $out_dir."/".$err_file);

# }

# closedir $vcf_dh;

# dieq error_mess."FIX ME!: \@in_files, \@out_files and \@err_files should containes the same nb of element" unless
#     (@in_files == @out_files) && (@in_files == @err_files);

# warnq info_mess.scalar(@in_files)." vcf files found";

# ###

# warnq info_mess."Formating files:";

# my $pm = new Parallel::ForkManager($nb_job); # job number

# foreach my $index (0..$#in_files) {

#     $pm->start && next;

#     my $in_file = $in_files[$index];
#     my $out_file = $out_files[$index];

#     warnq info_mess."Formating file: ".$in_file." (".($index + 1)."/".scalar(@in_files).")";
#     my $n_line = 1;
#     my @first_format;

#     my $in_fh = openIN($in_file);
#     my $out_fh = openOUT($out_file);

#     my ($meta, $vcf_header, $vep_meta) = skip_vcf_meta($in_fh, $vep_key);
#     my $vep_format = parse_vep_meta_line($vep_meta);

#     @kept_vep_annot = @$vep_format unless @kept_vep_annot;

#     while (<$in_fh>) {

# 	##################
# 	# 
# 	# 0: chromosome (ex: 11)
# 	# 1: Position: variant position (ex: 209898)
# 	# 2: variant ID
# 	# 3: Reference allele
# 	# 4: Variation allele
# 	# 5: Quality
# 	# 6: Filter 
# 	# 7: Info
# 	# 8: Format
# 	# 9: Others
# 	# 
# 	##################
# 	my ($chr,$pos,$rs,$ref,$alt,$info,$format,$other) = parse_vcf_line($_, 0..4, 7..9);
# 	my $info_table = parse_vcf_info($info);

# 	my $format_table = fill_vcf_format($format, $other);
# 	my $vep_info = &findAnnot($info_table, $vep_key);
# 	my $vep_infos = parse_vep_info($vep_info);
	
# 	my @format = sort(keys(%$format_table));
# 	my @value = ();

# 	# print header line
# 	if ($n_line == 1) {
	    
# 	    say $out_fh join("\t", "CHR", "POSITION", "REF", "ALT", @kept_vep_annot, @format);
# 	    @first_format = @format
	
# 	} 
	
# 	#
# 	foreach my $f (@first_format) {

# 	    my $v = $format_table->{$f} || ".";
# 	    push(@value, $v);
# 	}

# 	$n_line++;

# 	foreach my $vi (@$vep_infos) {

# 	    # return a hash table with key 
# 	    my $vep_table = fill_vep_table($vi, $vep_format);	 
# 	    my @vep_annot = &findAnnot($vep_table, @kept_vep_annot);
	    
# 	    say $out_fh join("\t", $chr, $pos, $ref, $alt, @vep_annot, @value);
# 	}
#     }

#     close_files($in_fh, $out_fh);

#     $pm->finish;

# }

# $pm->wait_all_children;

# warnq info_mess."All done";

# ##########
# #
# # SUB
# #
# ##########

# sub findAnnot {

#     my $table = shift;    
#     my @annot_to_return = (@_) ? 
# 	(@_) : 
# 	(sort(keys %$table)); # return all value having a key within the table if nothing is ask
#     my @r;

#     push @r, $table->{$_} || "" foreach @annot_to_return; # value = "" if key is missing 
    
#     warnq warn_mess."Nothing found" if @r == 0;

#     (@r == 1) ? 
# 	(return $r[0]) :
# 	(return @r);
# }


# sub fill_vcf_format {

#     my ($format, $value) = @_;
#     my $format_table;
#     my $sep = ":";
#     my @format = split(/$sep/, $format);
#     my @value = split(/$sep/, $value);

#     if(@format != @value) {

# 	warnq error_mess."\@format and \@value should contain the same nb of element: $format, $value";

#     } else {
	
# 	$format_table->{$format[$_]} = $value[$_] foreach 0..$#format; 
	
#     }

#     return $format_table;    
# }


sub configure {

    my $args = shift;    
    my $config = {};

    GetOptions(
        $config,
	'h',                        # print basic usage
	'help',                     # print compelt usage
	'verbose|v',                # print out a bit more info while running
	'quiet|q',                  # print nothing to STDERR
	'outdir|o=s',               # output directory
	'indir|i',               # output directory

	) or dieq error_mess."unexpected options, type -h or --help for help";


    if((defined $config->{h}) || !$args) {
	print &usage;
	die;
    }

    # if(defined $config->{help}) {
    # 	print &completUsage;
    # 	die;
    # }
    
    # check of brain sanity
    dieq error_mess."cannot be both quiet and verbose!" if $config->{verbose} && $config->{quiet};
    
    # check out directory:
    dieq error_mess."the indir directory has to be mentioned" unless $config->{indir};

    $config->{outdir} ||= "VCF";

    unless(-d $config->{outdir}) {

	dieq error_mess."cannot mkdir $config->{outdir}: $!" unless mkdir($config->{outdir});
	warnq info_mess."mkdir $config->{outdir} done successfully" if $config->{verbose}
    }
	
    # check forking: 
    $config->{fork} = 1 unless $config->{fork};
    dieq error_mess."fork must be a number" if $config->{fork} =~ /^\D+$/;
    dieq error_mess."fork number must be greater than 0" if $config->{fork} <= 0;
    
    return $config;
}
