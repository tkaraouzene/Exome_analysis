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

my $in_dir = "test";
my $out_dir = "test2";

my $nb_job = 3;

my $fastq_ext = ".fastq.gz";
my $in_pattern = "PRY-[^-]+-R";
my $out_pattern = "grex";

###########
#
# MAIN
#
###########


my %fastq_table;
## Retrieve fastq files
# Store it in a hash table: 
# $fastq_files{fastq_start} = (file1, file2)

warnq info_mess."Seeking fastq files...";

my $in_dh = openDIR($in_dir);

while (my $in_file = readdir $in_dh) {

    next unless $in_file =~/$fastq_ext$/;

    next unless $in_file =~/($in_pattern)/;

    my $template = $1;

    push(@{$fastq_table{$template}}, $in_dir."/".$in_file);
}

closedir($in_dh);

# Prepare output directory
unless(-d $out_dir) {

    dieq error_mess."cannot mkdir $out_dir: $!" unless mkdir($out_dir);
    warnq info_mess."mkdir $out_dir done successfully";
}

# start to zcat
my $pm = new Parallel::ForkManager($nb_job); # job number

my $i = 1;

foreach my $t (sort(keys %fastq_table)) {


    my $out_file = $out_dir."/".$out_pattern.$i.$fastq_ext;

    my $cmd = "zcat @{$fastq_table{$t}} >$out_file";
    $i++;
    $pm->start && next;

    print $cmd."\n";

    `$cmd`;

    $pm->finish;

}

$pm->wait_all_children;

print "All done\n";
