#!/usr/bin/perl -w

our $buildDir="/home/qa/deployment/build/";
our $scriptDir="/home/qa/deployment/script/";
our $deployDir="/srv/";

our $tomcatDir ="/srv/apache-tomcat/webapps/";
our $mklwsDir = "/srv/mkl-server/";
our $webScript="apache-tomcat.sh";
our $appScript="wsapp.sh";
our $mklwsFol = "mkl_ws";
our $cmsFol = "cms";
our $webFol = "web";
our $clientFol = "client";
our $wechatFol = "wechat";
our $bakDir = "/home/qa/deployment/bak/";

#copy new package
sub deployCmsServer(){
   print "------Begin deploy client-cms------\n";
   print "------Backup current cms------\n";
   chdir($tomcatDir);
   bakPkg($cmsFol);
   print "------Delete current webapps/cms------\n";
   system("rm -fr $tomcatDir/cms");
   print "------Copy client-cms to webapps/------\n";
   chdir($buildDir);
   system("cp -rf client-cms $tomcatDir/cms");
   print "------End of deploy client-cms------\n";
}


sub deployWebServer(){
   print "------Begin deploy client-web-pegasu------\n";
   print "------Backup current web------\n";
   chdir($tomcatDir);
   bakPkg($webFol);
   print "------Delete current webapps/web------\n";
   system("rm -fr $tomcatDir/web");
   print "------Copy client-web-pegasu to webapps/------\n";
   chdir($buildDir);
   system("cp -rf client-web-pegasus $tomcatDir/web");
   print "------End of deploy client-web-pegasu------\n";
}


sub deployClientServer(){
   print "------Begin deploy client------\n";
   print "------Backup current client------\n";
   chdir($tomcatDir);
   bakPkg($clientFol);
   print "------Delete current webapps/client------\n";
   system("rm -fr $tomcatDir/client");
   print "------Copy client to webapps/------\n";
   chdir($buildDir);
   system("cp -rf client-web $tomcatDir/client");
   print "------End of deploy client------\n";
}

sub deployWechatServer(){
   print "------Begin deploy Wechat------\n";
   print "------Backup current Wechat------\n";
   chdir($tomcatDir);
   bakPkg($wechatFol);
   print "------Delete current webapps/wechat------\n";
   system("rm -fr $tomcatDir/$wechatFol") if (-e "$tomcatDir/$wechatFol");
   print "------Copy client to webapps/------\n";
   chdir($buildDir);
   system("cp -rf $wechatFol $tomcatDir/$wechatFol");
   print "------End of deploy $wechatFol------\n";
}

sub deployMklwsServer(){
   print "------Begin deploy mkl_ws------\n";
   print "------Backup current mkl_ws------\n";
   chdir($mklwsDir);
   bakPkg($mklwsFol);
   print "------Delete current /srv/mkl-server/mkl_ws------\n";
   system("rm -rf $mklwsDir/mkl_ws"); 
   print "------Copy mkl_ws to /srv/------\n";
   chdir($buildDir);
   system("cp -rf mkl_ws $mklwsDir/");   
   print "------End of deploy mkl_ws------\n";
}

sub restartTomcat(){
   chdir($scriptDir);
   $output= `./$webScript restart`;
   print "----------------$output------------------\n";	
   if($output =~ /Exception/){
		print "exit!!!\n";
		exit 1;
   }else{
		print "Deploy Success!\n";

   }
}

sub bakPkg($){
	my $app = shift;
	my $currentDate = `date +"%Y-%m-%d-%H%M%S"`;
	chomp $currentDate;
	system("tar -zcvf $bakDir/$app.$currentDate.tar.gz ./$app");
}

if (@ARGV == 1){
	if ($ARGV[0] =~ /client-cms/i){
		deployCmsServer();
		restartTomcat();
	}
	elsif ($ARGV[0] =~ /client-web-pegasus/i){
		deployWebServer();
		restartTomcat();
	}
        elsif ($ARGV[0] =~ /client/i){
                deployClientServer();
                restartTomcat();
        }
	elsif ($ARGV[0] =~ /mkl_ws/i){
		deployMklwsServer();
		chdir($scriptDir);
		system("./$appScript restart");
	}
	elsif ($ARGV[0] =~ /wechat/i){
                deployWechatServer();
		restartTomcat();
        }
	elsif ($ARGV[0] =~ /all/){
		deployCmsServer();
		deployWebServer();
		deployWechatServer();
		deployClientServer();
		deployMklwsServer();
		restartTomcat();
		chdir($scriptDir);
                system("./$appScript restart");
	}
	else{
		if (-e "/srv/apache-tomcat/webapps/$ARGV[0]"){
			print "Webapp exist,Begin deploy $ARGV[0]...\n";
			system("rm -rf /srv/apache-tomcat/webapps/$ARGV[0]");
			chdir($buildDir);
			system("cp -rf  $ARGV[0] $tomcatDir/");
			restartTomcat();
		}else{

			print "unknow porject name\n";
			exit 1;
		}

	}
}else{
	print "Usage: $0 (all|mkl_ws|client|client-web-pegasus|client-cms|wechat)\n";
}
