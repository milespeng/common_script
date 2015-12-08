#!/usr/bin/perl -w
#use strict;
#Created by William Wu on 2015-02-27;
use Log::Log4perl;
use Config::Tiny;
our $logPath="/home/qa/ACD/log";
our $buildHome="/home/qa/ACD/build";


our $rsyncPathName="BuildHome";

sub logName(){
   my $today=`date  -d'0 day' +'%y%m%d' | tr -d '\r\n'`;
   #my $today = "2015-02-15";
   my $logFileName="$logPath/gocmobilepkgs2s3$today.log";
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
   chdir("$buildHome/$jobName");
   my $section = "general";
   my $conf = Config::Tiny->read("s3.conf");
    if ($conf->{$section} eq ""){
        print "Section doesn't exist, please check out s3.conf to find correct section!\n";
        exit(2);
    }
    our $s3path=$conf->{$section}->{s3path};
    our $filter=$conf->{$section}->{filter};
}

sub cp2BuildHome(){
   #Clean all files before copying;
   system("rm -fR $buildHome/$jobName/*") if (-e "$buildHome/$jobName");
   #Create folder if it doesn't exist
   system("mkdir -p $buildHome/$jobName") unless (-e "$buildHome/$jobName");
   #Copy all files to $buildHome/$jobName;
   $log->info("cp -fR $workSpace/lobby/s3.conf $buildHome/$jobName");
   system("cp -fR $workSpace/lobby/s3.conf $buildHome/$jobName");
   
   $log->info("cp -fR $workSpace/lobby/res/* $buildHome/$jobName");
   system("cp -fR $workSpace/lobby/res/* $buildHome/$jobName");
   
   $log->info("cp -fR $workSpace/lobby/scripts $buildHome/$jobName");
   system("cp -fR $workSpace/lobby/scripts $buildHome/$jobName");
}

sub sync2s3(){
   $log->info("s3cmd put -P --delete-removed --add-header=Cache-Control:no-cache --recursive $buildHome/$jobName/ $s3path");
   system("s3cmd put -P --delete-removed --add-header=Cache-Control:no-cache --recursive $buildHome/$jobName/ $s3path");
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

cp2BuildHome();
readConf();
sync2s3();
