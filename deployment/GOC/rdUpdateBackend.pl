#!/usr/bin/perl -w
#use strict;
use Log::Log4perl;
our @gmSever=('qa@54.215.252.134::','qa@54.215.221.100::');

#our @compileAll = ("mvn clean install -Ptest -DskipTests","mvn clean install -Pmobile_guest_test -DskipTests");
our $compileAll= "mvn clean install -Ptest -DskipTests";
our $facebookNFPath = "/home/qa/Git/goc_casino/";

our $CDPath="/home/qa/Git/goc_casino/common-dal";
our $CSPath="/home/qa/Git/goc_casino/common-server";
our $GSPath="/home/qa/Git/goc_casino/gameserver";
our $LSPath="/home/qa/Git/goc_casino/logserver";
our $TSPath="/home/qa/Git/goc_casino/taskserver";
our $BSPath="/home/qa/Git/goc_casino/bossserver";
our $PSPath="/home/qa/Git/goc_casino/pokerserver";
our $TraSPath="/home/qa/Git/goc_casino/trackserver";

our $GSbuildpath = "/home/qa/Git/goc_casino/gameserver/target/";
our $LSbuildpath = "/home/qa/Git/goc_casino/logserver/target/";
our $TSbuildpath = "/home/qa/Git/goc_casino/taskserver/target/";
our $BSbuildpath = "/home/qa/Git/goc_casino/bossserver/target/";
our $PSbuildpath = "/home/qa/Git/goc_casino/pokerserver/target/";
our $TraSbuildpath = "/home/qa/Git/goc_casino/trackserver/target/";


our $GSbuild = "gameserver.war";
our $LSbuild = "logserver.tar.gz";
our $TSbuild = "taskserver.tar.gz";
our $BSbuild = "bossserver.war";
our $PSbuild = "pokerserver.tar.gz";
our $TraSbuild = "trackserver.war";

our $GSFol = "gameserver";
our $LSFol = "logserver";
our $TSFol = "taskserver";
our $BSFol = "bossserver";
our $PSFol = "pokerserver";
our $TraSFol = "trackserver";
our $ClientFol = "client";

our @backupBuildPath=("/home/qa/deployment/build/goc","/home/qa/deployment/build/goc_guest");
our $GOCBuild="BuildHome";
our $svnLobbyPath="/home/qa/Git/goc_flash/webapp/lobby";

###############################################################################
sub logName(){
   my $today=`date  -d'0 day' +'%y%m%d' | tr -d '\r\n'`;
   my $logFileName="/home/qa/deployment/log/goc/goc_backend$today.log";
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

sub sendLogMail(){
   chdir("/home/qa/deployment/script");
   system ("./UpdateEmail.py goc goc_backend");
   $log->info("successfully send email");
}

sub updateFBAll(){  
   $log->info("-------------------Mail Starting--------------------");
   $log->info("\n---------------Start to update---------------");
   if ($update_module=~/servers/i){
      chdir("$facebookNFPath");
      $log->info("start updating goc_casino"); 
      my @updateFile = `git pull`;
      $log->info("@updateFile");
   }
   if ($update_module=~/client/i){
      chdir($svnLobbyPath);
      $log->info("start updating flash"); 
      my $svnUpdate=`git pull`;
      $log->info("$svnUpdate");
   }
   $log->info("---------------------------------------------------\n");
   $log->info("--------------------Mail Ending------------------------");
}

sub compileIsFailed($){
   my $log = shift;
   if ($log=~/BUILD FAILURE/){
      print "$log\n";
      print "Build failed, exit script!\n";
      exit(1);
   }
}

sub compileFBAll(){
   chdir("$facebookNFPath");
   $log->info("Start to compile all");
   my $buildLog=`$compileAll 2>&1`;
   compileIsFailed($buildLog);
   $log->info("Compile successfully");
   #Seperately create packages on both GOC and GOC Guest
   foreach(@backupBuildPath){
   #Create new fold to store backup files if folders don't exist.
      system("mkdir -p $_/$GSFol") unless (-e "$_/$GSFol");
      system("mkdir -p $_/$LSFol") unless (-e "$_/$LSFol");
      system("mkdir -p $_/$TSFol") unless (-e "$_/$TSFol");
      system("mkdir -p $_/$BSFol") unless (-e "$_/$BSFol");
      system("mkdir -p $_/$PSFol") unless (-e "$_/$PSFol");
   #system("mkdir $backupBuildPath[$id]/$TraSFol") unless (-e "$backupBuildPath[$id]/$TraSFol");
   
   #Clean all folders.
      system ("rm -rf $_/$GSFol/* $_/$LSFol/* $_/$TSFol/* $_/$BSFol/* $_/$PSFol/* ");
      chdir("$_/$GSFol");
      system ("jar xvf $GSbuildpath$GSbuild");
    
      chdir("$_/$TSFol");
      system ("tar zxvf $TSbuildpath$TSbuild");
      system ("cp -rf taskserver/* ./");
      system ("rm -rf taskserver");
         
      chdir("$_/$LSFol");
      system ("tar zxvf $LSbuildpath$LSbuild");
      system ("cp -rf logserver/* ./");
      system ("rm -rf logserver");
       
      chdir("$_/$BSFol");
      system ("jar xvf $BSbuildpath$BSbuild");
   
      chdir("$_/$PSFol");
      system ("tar zxvf $PSbuildpath$PSbuild");
      system ("cp -rf pokerserver/* ./");
      system ("rm -rf pokerserver");
      
      #chdir("$_/$TraSFol");
      #system ("jar xvf $TraSbuildpath$TraSbuild");
      #$log->info("Copy new build successfully");
   }
   #Copy configuration to goc_guest;
   my $guestSrvConf="src/main/resources/mobile_guest_test";
   $log->info("cp -f $GSPath/$guestSrvConf/* $backupBuildPath[1]/gameserver/WEB-INF/classes/");
   system("cp -f $GSPath/$guestSrvConf/* $backupBuildPath[1]/gameserver/WEB-INF/classes/");
   
   $log->info("cp -f $LSPath/$guestSrvConf/* $backupBuildPath[1]/logserver/conf/");
   system("cp -f $LSPath/$guestSrvConf/* $backupBuildPath[1]/logserver/conf/");
   
   $log->info("cp -f $TSPath/$guestSrvConf/* $backupBuildPath[1]/taskserver/conf/");
   system("cp -f $TSPath/$guestSrvConf/* $backupBuildPath[1]/taskserver/conf/");
   
   $log->info("cp -f $BSPath/$guestSrvConf/* $backupBuildPath[1]/bossserver/WEB-INF/classes/");
   system("cp -f $BSPath/$guestSrvConf/* $backupBuildPath[1]/bossserver/WEB-INF/classes/");
}

sub makeClient(){
   my $buildDir="/home/qa/deployment/build/goc/client";
   #Create client and og folder if it doesn't exist.
   system("mkdir $buildDir") unless (-e $buildDir);
   system("mkdir $buildDir/og") unless (-e "$buildDir/og");
   $log->info("Copy config.xml to client");
   system("cp -f $svnLobbyPath/config-testing.xml $buildDir/config.xml");
   
   $log->info("Copy unsubscribe.html to client");
   system("cp  -f $svnLobbyPath/unsubscribe.html $buildDir/unsubscribe.html");
   
   $log->info("Copy shell.html and Shell.swf to client");
   system("cp -f $svnLobbyPath/shell-testing.html $buildDir/shell.html");
   system("cp -f $svnLobbyPath/Shell.swf $buildDir/Shell.swf");
   
   #create a new timestamp for request argument
   my $newVersion;
   $newVersion=time();
   $log->info("new version:$newVersion");
   system ("perl -pi -e 's#swfVersion = \"(\\d+)\"#swfVersion = \"$newVersion\"#' $buildDir/shell.html");
   
   $log->info("Copy files in og folder to client");
   system("cp -f $svnLobbyPath/og/*.html $buildDir/og/");
}
sub rsync2Srv($$){
   #$id=0:GOC WEB or 1:GOC Guest
   #$mod means sync modules wanted
   my ($id,$mod)=@_;
   chdir("$backupBuildPath[$id]");
   if($mod=~/all|gameSrv/i){
      $log->info("Transfer game server");
      system("rsync -z -t -r --delete --itemize-changes --progress $GSFol $gmSever[$id]$GOCBuild");
   }
   if($mod=~/all|client/i && $id=~/0/){
      $log->info("Transfer client");
      system("rsync -z -t -r --delete --itemize-changes --progress $ClientFol $gmSever[$id]$GOCBuild");
   }
   if($mod=~/all|pokerSrv/i && $id=~/0/){
      $log->info("Transfer poker server");
      system("rsync -z -t -r --delete --itemize-changes --progress $PSFol $gmSever[$id]$GOCBuild");
   }
   if($mod=~/all|bossSrv/i){
      $log->info("Transfer boss server");
      system("rsync -z -t -r --delete --itemize-changes --progress $BSFol $gmSever[$id]$GOCBuild");   
   }
   if($mod=~/all|logSrv/i){
      $log->info("Transfer log server");
      system("rsync -z -t -r --delete --itemize-changes --progress $LSFol $gmSever[$id]$GOCBuild"); 
   }
   if($mod=~/all|taskSrv/i){
      $log->info("Transfer task server");
      system("rsync -z -t -r --delete --itemize-changes --progress $TSFol $gmSever[$id]$GOCBuild");
   }

#   if($mod=~/1|7/ && $id=~/0/){
#      $log->info("Transfer track server");
#      system("rsync -z -t -r --delete --itemize-changes --progress $TraSFol $gmSever[$id]$GOCBuild");
#   }
}

####################################################################
our $update_module=$ARGV[0];
our $compile_module=$ARGV[1];
our @platforms=split(/,/,$ARGV[2]);
our $sync_module=$ARGV[3];

initLog();
updateFBAll();
sendLogMail();

if ($compile_module=~/servers/i){
   $log->info("start compiling all");
   compileFBAll();
}
if ($compile_module=~/client/i){
   makeClient();
}

foreach(@platforms){
   if ($_=~/^goc$/i){
      $log->info("Sync backend to goc...");
      rsync2Srv(0,$sync_module);
   }
   if ($_=~/^goc_guest$/i){
      $log->info("Sync backend to goc_guest...");
      rsync2Srv(1,$sync_module);
   }  
}





