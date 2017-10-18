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

use my_warnings qw(printq warnq dieq info_mess error_mess warn_mess);
use my_file_manager qw(openDIR openIN openOUT close_files);

###########
#
# SETTINGS
#
###########

my $in_dir = "data";
my $out_dir = "out_test";
my $nb_job = 3;
my $in_ext = ".fq.gz";
my $out_ext = ".fastq.gz";
my $in_pattern = '(P.+)_L(\d)_(\d)';
my $out_pattern = "grex";

###########
#
# MAIN
#
###########


my $fastq_table = {};
## Retrieve fastq files
# Store it in a hash table: 
# $fastq_files->{fastq_start}->[$strand] = (file1, file2)

warnq info_mess."Seeking fastq files...";

my $in_dh = openDIR($in_dir);

while (my $in_file = readdir $in_dh) {

    next unless $in_file =~/$in_ext$/;
    next unless $in_file =~/$in_pattern/;

    my $name = $1;
    my $lane = $2;
    my $strand = $3;

    push(@{$fastq_table->{$name."_".$strand}}, $in_dir."/".$in_file);
}

closedir($in_dh);

# Prepare output directory
unless(-d $out_dir) {

    dieq error_mess."cannot mkdir $out_dir: $!" unless mkdir($out_dir);
    warnq info_mess."mkdir $out_dir done successfully";
}


# find last exome nb
warnq info_mess."Seeking last exome nb in $out_dir...";

my $out_dh = openDIR($out_dir);
my $last_exome = 0;

while (my $fastq_file = readdir $out_dh) {
    
    next unless $fastq_file =~/$out_ext$/;
    
    dieq error_mess."unexpected fastq format: $fastq_file" unless $fastq_file =~ /^$out_pattern(\d+)\./;

    my $exome_nb = $1;

    if ($exome_nb > $last_exome) {

	$last_exome = $exome_nb;

    }
}

# exome nb start
my $i = $last_exome + 1;

# start to zcat
my $pm = new Parallel::ForkManager($nb_job); # job number
warnq info_mess."Start to zcat files...";

foreach my $run (sort(keys %$fastq_table)) {

    dieq error_mess."unexpected run format: $run" unless $run =~ /^(.+)_(\d)$/;

    my $name = $1;
    my $strand = $2;
    
    # change exome nb
    my $nb = &exome_nb($i) or die;

    my $out_file = $out_dir."/".$out_pattern.$nb.".R".$strand.".".$out_ext;
    my $cmd = "zcat @{$fastq_table->{$run}} | gzip -c > $out_file";
    $i++;
    $pm->start && next;
    
    `$cmd`;
    
    $pm->finish;
}

$pm->wait_all_children;

warnq info_mess."All done\n";





###########
#
# SUB
#
###########

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
