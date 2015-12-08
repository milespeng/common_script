#!/usr/bin/perl -w
#use strict;
use Log::Log4perl;
use Config::Tiny;

our $logPath="/home/qa/ACD/log";
our $report="$logPath/report";
our $testcaseFile="/home/qa/ACD/script/soapui";
our $gdpAll="gdp_api,gdp_mweb,gdp_crm";
our $aglpAll="aglp_server,aglp_boss";

sub logName(){
   my $today=`date  -d'0 day' +'%y%m%d' | tr -d '\r\n'`;
   my $logFileName="$logPath/rdRunTestcases$today.log";
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



############################## main #############################
initLog();

if ( scalar(@ARGV) < 1){
   print "Usage: JOB_NAME\n";
   exit(1);
}else{
   our $jobName = $ARGV[0];
   $log->info("JobName=$jobName");
}

if ($jobName =~/gdp_all/i) {
   $jobName=$gdpAll
}
if ($jobName =~/aglp_all/i) {
   $jobName=$aglpAll
}


my @jobs = split(/,/,$jobName);
foreach(@jobs){   
   $jobName = $_;
   #if file exist
   if (! -e "$testcaseFile/$jobName/$jobName.xml"){
   $log->error("$jobName.xml doesn't exist!\n");
   exit(1);
   }
 
   $log->info("Start run testcases with soapUI...");

   #clean
   system("rm -rf $report/*");
   system("rm -rf *.log");


   #run
   system("/srv/soapUI/bin/testrunner.sh -r -I -R -f $report $testcaseFile/$jobName/$jobName.xml >$testcaseFile/$jobName/$jobName.log 2>&1");
   $result=`cat $testcaseFile/$jobName/$jobName.log`;
   print $result;

   #if ($result=~/ERROR/){
   #modify way to judge failure 
   if ($result!~/(0 failed)/){      
      print "Run failed, exit script!\n";
      exit(1);
   }
}