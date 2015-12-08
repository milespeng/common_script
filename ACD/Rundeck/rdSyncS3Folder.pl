#!/usr/bin/perl -w
#use strict;
#Created by William Wu on Nov 18 2015;
#Purpose: Sync files on S3 from testing to production.

use Config::Tiny;
our $result="";
our $cmd = "s3cmd sync -P --delete-removed --add-header=Cache-Control:no-cache --recursive";
our $conf = "/home/qa/ACD/script/rundeck/rdSyncS3Folder.ini";

sub readConf(){
   my $section = $jobName;
   my $conf = Config::Tiny->read($conf);
    if ($conf->{$section} eq ""){
        print "Section doesn't exist, please check out webclient2s3 to find correct section!\n";
        exit(1);
    }
    our $folders=$conf->{$section}->{folders};
    our $srcPath=$conf->{$section}->{srcpath};
    our $destPath=$conf->{$section}->{destpath};
}

sub isEmpty($){
   #Check if the folder is empty.
   my $path = shift;
   $result = `s3cmd du $srcPath/$path/`;
   $result =~/(\d+)\s+.*/;
   print "Folder $path Disk Usage:$1\n";
   if ($1 == 0) {
      print "Source path may be empty, please check out and try again later\n";
	  exit(1);
   }
}

sub syncFolder(){
   @folders = split(/,/,$folders);
   foreach(@folders){
      isEmpty($_);
      print "syncing $cmd $srcPath/$_/ $destPath/$version/$_/ ...\n";
      #system("$cmd $srcPath/$_/ $destPath/$version/$_/");
      $result = `$cmd $srcPath/$_/ $destPath/$version/$_/`;
   }
   if ($result=~/error/i) {
      print "$result\n";
      print "ERROR:failed to sync\n";
      exit(1);
   }else{
      print "sync folders successfully\n";
   }
}
######################################### Main Program ###########################################
if ( scalar(@ARGV) < 3){
   print "Usage: rdSyncS3Folder.pl [JOB_NAME] [Version] [ConfirmVersion]\n";
   exit(1);
}

if($ARGV[1] ne $ARGV[2]){
   print "$ARGV[1] $ARGV[2]\n";
   print "Version must be equal ConfirmVersion\n";
   exit(1);
}

our $jobName = $ARGV[0];
our $version = $ARGV[1];
print "Job Name:$jobName\n";
print "Version:$version\n";

readConf();
syncFolder();