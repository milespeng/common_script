#!/usr/bin/perl

use strict;
use POSIX qw(strftime);;
use Config::Tiny;

my $conf = "/home/qa/deployment/script/conf/rdDeploySrvs.ini";
#my $conf = "./conf/rdDeploySrvs.ini";
my $projectName = $ARGV[0];
my @projectName;
my ($buildPath,$deployPath,@deployPkgs,$pkgs,$script,$group);
my $time_now = strftime "%y%m%d%H%M%S",localtime;
our $result;
chomp($time_now);

#sub bakPkg($_){
#       my $app = shift;
#       system("tar -czf $bakDir/$app.$time_now.tar.gz ./$app >/dev/null 2>&1");
#}

sub deploySrvs(){
   #Copy all packages to folder in tomcat webapp
   chdir($deployPath);
   foreach (@deployPkgs){
      print " |__Backup $_\n";
      #     bakPkg($bkPkgs);
      print " |__done\n";
      print " |__Delete $_\n";
      system("rm -rf $deployPath/$_");
      print " |__done\n";
      print " |__Copy $_ to webapps/\n";
      chdir($buildPath);
      system("cp -rf $_ $deployPath/$_");
      print " |__End of deploy $_\n";
   }
}

sub restartService(){
        #restart service based on $projectName
        #chdir($scriptDir);
	print "$script\n";
	if($script =~ /none/i){
		print "this service donot need restart\n";
	}else{
		$result = `$script`;
		print "$result\n";
	}
	
    if($result =~ /Exception|ERROR/i){
        print "Failed to restart and exit\n";
        exit 1;
    }else{
        print "----------------------Deploy Success!---------------------\n\n";
    }
}

sub help(){
    print "############ Help ############\n";
    print "/home/qa/deployment/script/rdDeploySrvs.pl [YOUR_ProjectName]\n";
    print "eg: /home/qa/deployment/script/rdDeploySrvs.pl goldpay -> deploy goldpay\n";
    print "eg: /home/qa/deployment/script/rdDeploySrvs.pl agas -> deploy agas\n";
    print "eg: /home/qa/deployment/script/rdDeploySrvs.pl aglp -> deploy aglp\n";
    print "eg: /home/qa/deployment/script/rdDeploySrvs.pl tpps -> deploy tpps\n";
    print "##############################\n";
}

################################### Main Program #################################

if (scalar(@ARGV) != 1){
        &help();
        exit 1;
}
#readConf();

#Read config from rdDeploySrvs.ini.
my $conf = Config::Tiny->read("$conf") or die "$conf is not exist\n";
@projectName=split(/,/,$projectName);
foreach (@projectName){
        print "\$_=$_\n";
        if ($conf->{$_} eq ""){
                print "$_ doesn't exist, please check out rdDeploySrvs.ini to find correct section!\n";
                exit(2);
        }
        $buildPath=$conf->{$_}->{buildPath};
        $deployPath=$conf->{$_}->{deployPath};
        $pkgs=$conf->{$_}->{deployPkgs};
        $script=$conf->{$_}->{script};
        @deployPkgs=split(/,/,$pkgs);
	print " *--Begin deploy $_\n";
        deploySrvs();
        restartService();
}
