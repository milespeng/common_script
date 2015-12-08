#!/usr/bin/perl -w
#use strict;
our $logPath="/home/qa/ACD/log";
our $buildHome="/home/qa/ACD/build";
our $gitFlahHome="/home/qa/Git/goc_flash/";
our $lobbyHome="/home/qa/Git/goc_flash/goc_flash_webapp/lobby";
our $lobbyBranch="release_B";

sub cp2BuildHome(){
   #Create client and og folder if it doesn't exist.
   system("mkdir $buildHome/$jobName/client") unless (-e "$buildHome/$jobName/client");
   system("mkdir $buildHome/$jobName/client/og") unless (-e "$buildHome/$jobName/client/og");
   chdir("$buildHome/$jobName/client");
   
   #print "Copy config.xml to client\n";
   #system("cp -f $lobbyHome/config-testing.xml ./config.xml");
   
   print "Copy unsubscribe.html to client\n";
   system("cp  -f $lobbyHome/unsubscribe.html ./unsubscribe.html");
   
   print "Move shell.html and Shell.swf to client\n";
   system("mv -f $buildHome/$jobName/gameserver/shell-testing.html ./shell.html");
   system("cp -f $lobbyHome/Shell.swf ./");
   
   #create a new timestamp for request argument
   my $newVersion;
   $newVersion=time();
   #print "new version:$newVersion\n";
   system ("perl -pi -e 's#swfVersion = \"(\\d+)\"#swfVersion = \"$newVersion\"#' ./shell.html");
   print "Copy files in og folder to client\n";
   system("cp -f $lobbyHome/og/*.html ./og/");
}

sub checkoutLobbyB(){
   print "Git checking out $lobbyBranch\n";
   chdir("$gitFlahHome\/goc_flash_webapp");
   system("git checkout $lobbyBranch");
   $result=`git pull`;
   print "$result\n";
   chdir("$gitFlahHome");
   $result=`ant -f goc_flash_web/goc_flash_lobby/Shell/build.xml`;
   print "$result\n";
}

################################################################################
if ( scalar(@ARGV) < 1){
   print "Usage: buildGocLobby JOB_NAME";
   exit(1);
}else{
    our $jobName = $ARGV[0];
	checkoutLobbyB();
    cp2BuildHome();
    print "End of building GOC lobby!!!\n\n\n";
}


