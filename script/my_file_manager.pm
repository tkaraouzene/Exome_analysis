#!/usr/bin/env perl

package my_file_manager;
require Exporter ;

use strict;
use warnings;

use my_warnings qw(warnq dieq error_mess info_mess warn_mess);
use Scalar::Util qw(openhandle);

our @ISA = qw(Exporter) ;
our @EXPORT_OK = qw(openDIR openIN openOUT delete_empty_file close_files cat_files replace_files exist_dir) ;

sub openIN {
    
    ######################
    # open a file for reading (
    # can automatically manage compressed file (with .gz extention)
    # 
    # openIN($file)
    # openIN($file1,file2,...)
    #
    # $opt:
    #  - $opt->{mode} = opening mode (< as default)
    #  - $opt->{verbose} = print warn message if necessary
    #  - $opt->{safe} = same as $opt->{verbose}
    #
    # return filehandle
    ######################    

    warnq warn_mess."no file to open" unless @_;
   
    my $opt = pop @_ if ref $_[$#_] eq "HASH";
    my $mode = $opt->{mode} || "<";
    my $verbose = $opt->{verbose};
    my @fh;

    foreach my $f (@_) {

	if (!-e $f) {
	
	    dieq error_mess.$f." does not exist";
	    next;
	}

	if (-z $f && $verbose) {

	    warnq warn_mess."$f is empty";
	    next;	    
	}

	my $fh;
	
	if ($f =~ /.gz$/) {

	    open $fh, "gunzip -c ".$mode.$f." |" || dieq error_mess."cannot openGz  file: $f: $!";

	} else {
	    
	    open $fh, $mode.$f || dieq error_mess."cannot open file: $f: $!";
	    
	}

	
	
	push @fh, $fh;

    }

    (@fh == 1) ?
	(return $fh[0]) : 
	(return @fh);
}

sub openOUT {

    ######################
    # open a file for writting
    #
    # openIN($file)
    # openIN($file1,..$file2,\%opt)
    #
    # $opt:
    #  - $opt->{mode} = opening mode (default = ">")
    #  - $opt->{safe} = if defined: do not open an already existing file
    #  - $opt->{verbose} = print warn message if necessary
    #  - $opt->{v} = same as $opt->{verbose}
    #
    # return filehandle
    ######################    
 
    warnq warn_mess."no file to open" unless @_;
   
    my $opt = pop @_ if ref $_[$#_] eq "HASH";
    my $mode = $opt->{mode} || ">";
    my @fh;
    
    foreach my $f (@_) {
	
	dieq error_mess."$f already exists, cannot open if in safe mode" if -e $f && $opt->{safe};

	if ($opt->{v} || $opt->{verbose}) {
	    warnq warn_mess."$f already exists and had non zero size, it has been overwritten" if $mode eq ">" && -s $f;
	}

	open my $fh, $mode.$f or dieq error_mess."cannot open file: $f: $!";	
	push @fh, $fh;
    }
	
    (@fh == 1) ?
	(return $fh[0]) : 
	(return @fh);
}

sub openDIR {

    my @r;

    foreach my $dir (@_) {

	opendir my $dir_dh,$dir || dieq error_mess."cannot opendir $dir: $!";
	push @r, $dir_dh;
    }

    (@r == 1) ?
	(return $r[0]) :
	(return @r);
}

sub cat_files {

    my ($tmp_fh,$final_fh,$tmp_file) = @_;
    
    print $final_fh $_ while <$tmp_fh>;
    
    close $tmp_fh;
    

    if (defined $tmp_file) {

	dieq error_mess."cannot unlink($tmp_file): $!" unless unlink $tmp_file;
    }


    return;
}

sub close_files {
    
    foreach my $fh (@_) {
	
	unless (defined openhandle $fh) {
	    my $mess = " is not a filehandle, skiping it";
	    $mess = $fh.":".$mess if $fh;
	    warnq warn_mess.$mess;
    	    next;	    
	}
    }
    return;
}

sub replace_files {

    my ($f1,$f2) = @_;

    dieq error_mess."Could not unlink $f2: $!" unless unlink $f2;
    dieq error_mess."Could not rename $f1: $!" unless rename $f1,$f2;

    return;
}



sub exist_dir {
   
    #####
    # 
    # Check if a directory exists
    # Take one argument (directory path)
    # TODO: change the function so it can takes a list of directory
    # return 1 if the directory exist, undef otherwise
    #
    #####
    
    my $dir = shift;

    unless ($dir) {
	warnq error_mess."no specified directory";
	return;
    }
     
    unless (-d $dir) {

	warnq error_mess."the directory: $dir does not exist";
	return;

    }

    return 1;

}



sub delete_empty_file {

    my $status = 1;

    foreach my $error_file (@_) {
	
	if (-z $error_file) {
	    
	    warnq info_mess."$error_file is empty, deleting it";
	    warnq warn_mess."Can't delete empty file '$error_file': $!" unless unlink($error_file);
	    
	}

    }

    return $status;

}
