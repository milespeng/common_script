#!/usr/bin/perl -w
#use strict;
####################################################
#   Created by william on Feb 26 2013
#   Purpose: Pull flash from git and sync to S3
#   Change Logs:
#   Jul 24 2015
#       Choose which branch to pull
#   Sep 01 2015
#       checkout branch before compile, in case compile under the wrong branch
#   Sep 22 2015 put frontend serverClient/ to server side
####################################################

use Log::Log4perl;

our $build;
our $buildDir;
our $buildLobbyDir;
our $flashS3Dir;
our $serverDir;

our $version;
our $timeStamp = time();

our $flashRootP="/home/qa/Git/goc_flash";
our $flashF="$flashRootP\/goc_flash_web";
our $flashBaseF="goc_flash_baselineslot";
our $flashComF="Common";
our $flashLobF="goc_flash_lobby";
our $flashTabF="goc_flash_tablegame";
our $flashWebP="$flashRootP\/goc_flash_webapp/";



sub logName(){
   my $today=`date  -d'0 day' +'%y%m%d' | tr -d '\r\n'`;
   my $logFileName="/home/qa/deployment/log/goc/goc_frontend$today.log";
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
   system ("./UpdateEmail.py goc goc_frontend");
   $log->info("successfully send email");
}

sub checkoutBranch($){
   my $branch=shift;
   $log->info("Your input branch name is: $branch");
   $result = `git reset --hard 2>&1`;
   isStepFailed($result);
   $result = `git checkout $branch 2>&1`;
   isStepFailed($result);
   $log->info("successfully checkout branch.");
}

sub build($){
   my $buildFile=shift;
   $log->info("Your build xml is: $buildFile");
   $log->info("Build $buildFile");
   $result = `ant -f $buildFile 2>&1`;
   isStepFailed($result);
}

sub updateAndCom()
{
   $log->info("-------------------Mail Starting--------------------");
   $log->info("---------------Begin to update flash-------------");

   chdir("$flashF");
   $log->info("Update $flashF");
   checkoutBranch("$update_branch");
   our $updateFile1 = `git pull`;
   $log->info($updateFile1);

   $log->info("---------------Begin to update flash webapp-------------");

   chdir("$flashWebP");
   $log->info("Update $flashWebP");
   checkoutBranch("$update_branch");
   our $updateFile2 = `git pull`;
   $log->info($updateFile2);

   $log->info("---------------------------------------------------");
   $log->info("-------------------Mail Ending--------------------");   

   $log->info("Begin to compile lobby");	
   chdir("$flashRootP/");
   if ($updateFile1!~/^Already up-to-date/ || $updateFile2!~/^Already up-to-date/){
      compileLobby("all");
      compileWebapp();
   }
   $log->info("Finished to compile lobby");   

}
sub isStepFailed($){
   my $msg=shift;
   print "$msg\n";
   if($msg=~/BUILD FAILED|error/i){
      $log->info("Step failed, exit script");
      exit(1);
   }
}
sub compileLobby($){
   my $module=shift; #module: lib, lobby, poker
   
   chdir("$flashF");
   $log->info("Checkout $update_branch for lobby");
   checkoutBranch("$update_branch");
   
   if ($module=~/lib|all/i){
      build("$flashF\/$flashComF\/build.xml");
   }
	
   if ($module=~/lobby|all/i){
      build("$flashF\/$flashLobF\/Shell\/build.xml");
      build("$flashF\/$flashLobF\/LobbyUI\/build_enUS.xml");
      build("$flashF\/$flashLobF\/LobbyUI\/build_zhTW.xml");
      build("$flashF\/$flashLobF\/LobbyUI\/build_thTH.xml");
      build("$flashF\/$flashLobF\/LobbyUI\/build_esES.xml");
      build("$flashF\/$flashLobF\/Lobby\/build.xml");
      #build("$flashF\/$flashLobF\/LeaderBoard\/build_en_US.xml");
      #build("$flashF\/$flashLobF\/LeaderBoard\/build_th_TH.xml");
      #build("$flashF\/$flashLobF\/LeaderBoard\/build_zh_TW.xml");
      #build("$flashF\/$flashLobF\/LeaderBoard\/build_es_ES.xml");

   }
   if ($module=~/poker|all/i){
      build("$flashF\/$flashTabF\/PokerGame\/build.xml");
   }

}
sub compileWebapp(){
   chdir("$flashWebP");
  
   $log->info("Checkout $update_branch for flash webapp");
   checkoutBranch("$update_branch");
  
   if (-e "$build/onlineGameFlash.war"){
      $log->info("Clean files in folder $build/onlineGameFlash.war");
      system("rm -fR $build/onlineGameFlash.war/*");    
   }
   
   $log->info("Begin to export webapp files");
   chdir("$flashRootP");
   system("cp -r ./goc_flash_webapp/casino $buildDir");
   system("cp -r ./goc_flash_webapp/lobby $buildDir");
   
   $log->info("Create client folder...");
   system("mkdir -p $build/onlineGameFlash.war/client");
 
   $log->info("Move configuration to client folder...");
   chdir("$buildDir");
   system("mv ./lobby/Shell.swf ./client");  
   system("mv -f ./lobby/serverClient/* ./client");
   system("mv -f ./client/config_test.xml ./client/config.xml");
   system("mv -f ./client/config_test.js ./client/config.js");
   system("sed -i 's/\$timestamp/$timeStamp/g' ./client/config.js");
}

sub getDir(){
   if($update_branch=~/release_A/i){
      $flashS3Dir="GocTestA";
      $build='/home/qa/deployment/build/goc_a';
      $buildDir='/home/qa/deployment/build/goc_a/onlineGameFlash.war';
      $buildLobbyDir='/home/qa/deployment/build/goc_a/onlineGameFlash.war/lobby';
      $serverDir="qa\@54.215.252.134::DeploymentHome/apache-tomcat/webapps/client";
   }
   if($update_branch=~/release_B/i){
      $flashS3Dir="GocTestB";
      $build='/home/qa/deployment/build/goc_b';
      $buildDir='/home/qa/deployment/build/goc_b/onlineGameFlash.war';
      $buildLobbyDir='/home/qa/deployment/build/goc_b/onlineGameFlash.war/lobby';
      $serverDir="qa\@52.8.220.85::DeploymentHome/apache-tomcat/webapps/client";      
   }
	
}

####################################### main Program ########################################
if (scalar(@ARGV)<3){
   print "Usage: rdUpdateFrontend.pl [update_module] [sync_module] [update_branch]\n e.g. rdUpdateFrontend.pl update_compile casino,lobby,conf  release_A\n";
   exit(1);
}
our $update_module=$ARGV[0];
our $sync_module=$ARGV[1];
our $update_branch=$ARGV[2];

initLog();
getDir();

if($update_module=~/update_compile/i){
   updateAndCom();	
}
if($update_module=~/compile_all/i){
   compileLobby("all");
   compileWebapp();	
}

chdir("/home/qa/deployment/script");
if($sync_module=~/all|casino/i){
   $log->info("Sync casino flash from EC2 to S3 $flashS3Dir");
   system("./SyncFlash.py $flashS3Dir casino");
}
if($sync_module=~/all|lobby/i){
   $log->info("Sync lobby flash from EC2 to S3 $flashS3Dir");
   system("./SyncFlash.py $flashS3Dir lobby");
}
if($sync_module=~/all|client/i){
   $log->info("Rsync configuration files to $serverDir");
   system("rsync -q -z -t -r --delete --itemize-changes $buildDir/client/  $serverDir");
}
if($sync_module=~/all|casino|lobby|client/i){
   sendLogMail();	
}