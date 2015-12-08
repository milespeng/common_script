#!/usr/bin/perl -w
#use strict;
use Log::Log4perl;
use Config::Tiny;

###############################################################################
sub readConf(){
   print "Now section is $section and start reading config file...\n";
   my $conf = Config::Tiny->read("./ini/$project.ini") || die "$project.ini, ERROR:$!\n";
   #my $conf = Config::Tiny->read("GoldPay.ini");
   if ($conf->{$section} eq ""){
      print "Section name doesn't exist, please check  $section find correct section!\n";
      exit(1);
   }

   our $buildName = $conf->{$section}->{buildName};
   our $tomcatName = $conf->{$section}->{tomcatName};
   my $uploadPkgs = $conf->{$section}->{uploadPkgs};
   our $releaseConf = $conf->{$section}->{releaseConf};
   our @uploadPkgs = split(/,/,$uploadPkgs);
   
   our $buildHomePath = $conf->{$section}->{buildHomePath};
   our $testSrv =$conf->{$section}->{testSrv};   
   
   my $destSrvs = $conf->{$section}->{destSrvs};
   our @destSrvs = split(/,/,$destSrvs);   
   our $destUser = $conf->{$section}->{destUser};
   our $destPwd = $conf->{$section}->{destPwd};
   our $destPort = $conf->{$section}->{destPort};
   our $destPath = $conf->{$section}->{destPath};
}
  
#sub getConfList(){
#   my @files = glob("$buildHomePath/script/conf/*.conf");
#   my $index = 0;
#   print "Config List:\n";
#   foreach(@files){
#      if ($_=~/$buildName/i){
#         print "$index: $_\n";
#         $index++;
#      }
#   }
#   print "quit\n";
#   print "Please choose number of configuration you need(e.g. 1 or 2 or quit):";
#   chomp($result = <STDIN>);
#   $result=lc($result);
#   if ($result=~/quit/i){
#      print "Doesn't choose anything\n";
#   }else{
#      our $releaseConf=$files[$result];
#   }
#}

sub copyPkgs(){
   print "--------Start to get package-------\n";
   system("mkdir -p $buildHomePath/build/$buildName") unless (-e "$buildHomePath/build/$buildName"); 
   chdir("$buildHomePath/build/$buildName");
   #clean all files in folder
   system("rm -fr $buildHomePath/build/$buildName/*");
   foreach(@uploadPkgs){
      if ($_=~/^mkl_ws$/i){
         system("rsync -vzrtopg --delete --progress qa\@$testSrv"."::"."DeploymentHome/mkl-server/$_/ ./$_");   
      }else{
         system("rsync -vzrtopg --delete --progress qa\@$testSrv"."::"."DeploymentHome/$tomcatName/webapps/$_/ ./$_");
#         system("rsync -vzrtopg --delete --progress qa\@$testSrv"."::"."DeploymentHome/apache-tomcat/webapps/$_/ ./$_");
      }
   }
}

sub createPkgs(){
   #print "Start creating packages...\n";
   chdir("$buildHomePath/build/$buildName");
   foreach(@uploadPkgs){
      print "Start creating $_...\n";
      system("tar -zcf $_.tar.gz ./$_");
   }
   
   # need backup packages for production 
   if ($section=~/production/i){
      print "Backup packages to $buildHomePath/bak/$buildName folder...\n";
      system("mkdir -p $buildHomePath/bak/$buildName") unless (-e "$buildHomePath/bak/$buildName");
      delExpireBak(30); #delete bak file expire 30 days.
      my $time=`date +%Y-%m-%d`;
      chomp($time);
      my @tar = glob "$buildHomePath/build/$buildName/*.tar.gz";
      foreach(@tar){
         $_ = ~/$buildHomePath\/build\/$buildName\/(.*)\.tar\.gz/;
         my $file=$1;
         #print "tar = $_\n pkg = $file\n";
         print "pkg = $file\n";
         system("cp -f $buildHomePath/build/$buildName/$file.tar.gz $buildHomePath/bak/$buildName/$file-$time.tar.gz");    
      }
   }
}

sub delExpireBak($){
   my $expire = shift; #Unit:day
   $expire = $expire*24*60*60;
   my @files = glob("$buildHomePath/bak/$buildName/*");
   foreach(@files){
      if(time()-(stat($_))[9]>$expire){
         print "Delete file $_\n";
         unlink($_);
      }
   }
}

sub uploadPkgs(){
   chdir("$buildHomePath/build/$buildName");
   foreach $pkg (@uploadPkgs){
      foreach $srv (@destSrvs){
         print "Start uploading $pkg to $srv\n";
         system("pscp -pw $destPwd -P $destPort ./$pkg.tar.gz $destUser\@$srv:/$destPath/"); 
      }
   }
   if ($section=~/production/i){
      print "Backup packages to S3 on AWS\n";
      print "s3cmd --delete-removed sync $buildHomePath/bak/$buildName/ s3://aspectgaming-databackup/pkg/$buildName/\n";
      system("s3cmd --delete-removed sync $buildHomePath/bak/$buildName/ s3://aspectgaming-databackup/pkg/$buildName/");
   }
}

############################## Main program ######################################
if (scalar(@ARGV)<2){
   print "Usage: releaseSrvs.pl [project name] [section name in project file]\n e.g. releseSrvs.pl pal production\n";
   exit(1);
}
our $project = $ARGV[0];
our $section = $ARGV[1];
readConf();
print "$tomcatName\n";

print "Do you want to copy packages from test server?[y/n]";
chomp($result = <STDIN>);
$result=lc($result);
if ($result eq "y"){
   copyPkgs();
}

print "Do you want to modify configuration and build tar packages?[y/n]";
chomp($result = <STDIN>);
$result = lc($result);
if ($result eq "y"){
   print "$buildHomePath/script/common/modifyConfig.py $releaseConf\n";
   system("$buildHomePath/script/common/modifyConfig.py $releaseConf");
   createPkgs();
}

print "Do you want to upload packages to servers?[y/n]";
chomp($result = <STDIN>);
$result = lc($result);
if ($result eq "y"){
   uploadPkgs();
}
