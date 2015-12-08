#!/usr/bin/perl -w
#use strict;
#Created by William Wu on Jul 6 2015;
#Purpose: Upload static resources to S3 that include html and image etc.
#Modified by William Wu Jul 27 2015
#Support to upload web clients to S3 or EC2
#If folder is empty or not exist, won't sync

use Log::Log4perl;
use Config::Tiny;
our $logPath="/home/qa/ACD/log";
our $buildHome="/home/qa/ACD/build";

sub logName(){
   my $today=`date  -d'0 day' +'%y%m%d' | tr -d '\r\n'`;
   #my $today = "2015-02-15";
   my $logFileName="$logPath/webclient2s3$today.log";
   return $logFileName;
}

sub initLog(){
   my $conf = q{
      log4perl.rootLogger = INFO, Logfile, Screen
      log4perl.appender.Logfile = Log::Log4perl::Appender::File
      log4perl.appender.Logfile.filename = sub { logName(); };
      log4perl.appender.Logfile.layout = Log::Log4perl::Layout::PatternLayout
      log4perl.appender.Logfile.layout.ConversionPattern = %d %p %F %L - %m%n     
      log4perl.appender.Screen = Log::Log4perl::Appender::Screen
      log4perl.appender.Screen.stderr = 0
      log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
      log4perl.appender.Screen.layout.ConversionPattern = %d %p %F %L - %m%n
   };
   Log::Log4perl::init(\$conf);
   our $log = Log::Log4perl::get_logger();
}

sub readConf(){
   my $section = $jobName;
   my $conf = Config::Tiny->read("uploadwebclient.ini");
    if ($conf->{$section} eq ""){
        print "Section doesn't exist, please check out webclient2s3 to find correct section!\n";
        exit(2);
    }
    our $srcpath=$conf->{$section}->{srcpath};
    our $destpath=$conf->{$section}->{destpath};
    our $cmd=$conf->{$section}->{cmd};
}

sub cp2BuildHome(){
   #Clean all files before copying;
   system("rm -fR $buildHome/$jobName/*") if (-e "$buildHome/$jobName");
   #Create folder if it doesn't exist
   system("mkdir -p $buildHome/$jobName") unless (-e "$buildHome/$jobName");
   
   #Copy all files to $buildHome/$jobName;
   $log->info("cp -fR $workSpace/* $buildHome/$jobName/");
   system("cp -fR $workSpace/* $buildHome/$jobName/");
   
   chdir("$buildHome/$jobName");
   $log->info("Cleaning git folder...");
   system("find . -type d -name \".git\"|xargs rm -rf"); 
}

sub upload($){
   my $path = shift;
   $log->info("$cmd $buildHome/$jobName/$path $destpath/$path");
   system("$cmd $buildHome/$jobName/$path $destpath/$path");
}

sub syncFiles(){
	if ($srcpath=~/all/i){
		upload("");
	}else{
		our @srcpath = split(/,/,$srcpath);
		foreach(@srcpath){
			if (checkFolder($_)){
				upload($_);
			}else{
				$log->info("$_ doesn't exist or is empty");
			}
		}
	}
}

sub checkFolder($){
	my $dir = shift;
	@dir_files = <$dir/*>;
	my $folderValid;
	if (-e $dir){	
		if (@dir_files){
			$folderValid = 1;
		}else{
			$folderValid = 0;
		}
	}else{
			$folderValid = 0;
	}
	return($folderValid);  
}
######################################### Main Program ###########################################
initLog();
if ( scalar(@ARGV) < 2){
   print "Usage: gocmobilepkgs2s3.pl [JOB_NAME] [WORKSPACE]\n";
   exit(1);
}else{
   our $jobName = $ARGV[0];
   our $workSpace = $ARGV[1];
   $log->info("WorkSpace=$workSpace");
   $log->info("JobName=$jobName");
}

readConf();
cp2BuildHome();
syncFiles();
