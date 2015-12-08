#!/usr/bin/perl -w
#use strict;
#Created by William Wu on 2015-02-27;
use Log::Log4perl;
use Config::Tiny;
our $acdHome="/home/qa/ACD";
our $logPath="$acdHome/log";
our $buildHome="$acdHome/build";

our $rsyncPathName="BuildHome";


sub readConf(){
   my $section = $jobName;
   my $conf = Config::Tiny->read("rsync2testsrv.ini");
    if ($conf->{$section} eq ""){
        print "Section doesn't exist, please check out rsync2testsrv.ini to find correct section!\n";
        exit(2);
    }
    our $buildType=$conf->{$section}->{BuildType};
    our $pkgs=$conf->{$section}->{PKGs};
    our $rsyncSrv=$conf->{$section}->{RsyncSrv};
    our $folder=$conf->{$section}->{Folder};
    $log->info("\$buildType=$buildType \$pkgs=$pkgs \$rsyncSrv=$rsyncSrv \$folder=$folder");
}

sub logName(){
   my $today=`date  -d'0 day' +'%y%m%d' | tr -d '\r\n'`;
   #my $today = "2015-02-15";
   my $logFileName="$logPath/rsync2testsrv$today.log";
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

sub splitName($){
   my $pkg = shift;
   if ($pkg =~/(\w+|\w+-\w+|\w+-\w+-\w+).(war|tar.gz)$/){
      our $pkgName=$1;
      our $extension=$2;
      $log->info("Package Name:$pkgName");
      $log->info("Extension:$extension");
   }
   #Find where is this war or gz package in the workspace
   if(-e "$workSpace/$pkgName/target/$pkg"){
      our $sourcePath = "$workSpace/$pkgName/target";
   }
   elsif(-e "$workSpace/target/$pkg"){
      our $sourcePath = "$workSpace/target";
   }
   $log->info("Source Path=$sourcePath");
}

sub cp2BuildHome(){
   my @pkgs = split(/,/,$pkgs);
   if ($buildType eq "maven"){
      foreach(@pkgs){
         splitName($_);       
         if($extension=~/war/){
            system("mkdir -p $buildHome/$folder/$pkgName") unless (-e "$buildHome/$folder/$pkgName");         
            system("rm -fr $buildHome/$folder/$pkgName/*");            
            chdir("$buildHome/$folder/$pkgName");
            system("cp -fR $sourcePath/$pkgName/* ./");
	 }
         elsif($extension=~/tar.gz/){                                                #Derectly extract it if extension is tar.gz.
            chdir("$buildHome/$folder");
            system("rm -fr $buildHome/$folder/$pkgName");
            $log->info("tar zxf $sourcePath/$_");
            system("tar zxf $sourcePath/$_");
         }
      }
   }
   if ($buildType eq "go"){
      system("rm -fR $buildHome/$folder/mkl_ws") if (-e "$buildHome/$folder/mkl_ws");
      $log->info("cp -fR $workSpace/mkl_ws $buildHome/$folder");
      system("cp -fR $workSpace/mkl_ws $buildHome/$folder");                            #Copy mkl_ws fold to build home. 
   }
}

sub sync2srv(){
   my @rsyncSrv = split(/,/,$rsyncSrv);
   my $localHome="$buildHome/$folder";
   foreach(@rsyncSrv){
      $srv = "qa\@$_\:\:";
      $log->info("rsync -z -t -r --delete --itemize-changes --progress $localHome/* $srv$rsyncPathName");
      #system("rsync -z -t -r --delete --itemize-changes --progress $buildHome/$jobName/* $srv$rsyncPathName"); #rsync files to server
      system("rsync -q -z -t -r --delete --itemize-changes $localHome/* $srv$rsyncPathName"); #rsync files to server         
   }
}

######################################### Main Program ###########################################
initLog();
$log->info("\n\n\nStart rsync to server...");
if ( scalar(@ARGV) < 2){
   print "Usage: rsync2testsrv JOB_NAME WORKSPACE";
   exit(1);
}else{
   our $jobName = $ARGV[0];
   our $workSpace = $ARGV[1];
   $log->info("WorkSpace=$workSpace");
   $log->info("JobName=$jobName");
}

readConf();
$log->info("BuildHome=$buildHome/$folder\n");
cp2BuildHome();
sync2srv();
$log->info("End of rsync!!!\n\n\n");
