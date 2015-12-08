#!/usr/bin/perl -w
#use strict;
use Log::Log4perl;
use Config::Tiny;

our $buildPath;
our @pkgs=();
our @webAppName=();
our @srvAppName=();
our ($homePath,$sourcePath);

our %app_Folder=(
   "apiFol"=>"",
   "crmFol"=>"",
   "mwebFol"=>""
);

our %app_logfile=(
   "apiLog4jFile"=>"",
   "crmLog4jFile"=>"",
   "mwebLog4jFile"=>""
);

#Destination Path
#our %api_Dest=(
 #  "api_destServerIp"=>"",
  # "api_destServerPath"=>"",
   #"api_destUser"=>"",
   #"api_destPass"=>"",
   #"api_destPort"=>""
#);

our %crm_Dest=(
   "crm_destServerIp"=>"",
   "crm_destServerPath"=>"",
   "crm_destUser"=>"",
   "crm_destPass"=>"",
   "crm_destPort"=>""
);

our %mweb_Dest=(
   "mweb_destServerIp"=>"",
   "mweb_destServerPath"=>"",
   "mweb_destUser"=>"",
   "mweb_destPass"=>"",
   "mweb_destPort"=>""
);


our %DB=(
   "dbHostName"=>"",
   "gdqDbName"=>"",
   "dbUserName"=>"",
   "dbPassword"=>""   
);

our %Redis=(
   "gdqRedisSessionHost"=>"",
   "gdqRedisSessionPort"=>"",
   "gdqRedisCommonHost"=>"",
   "gdqRedisCommonPort"=>"",
);

our %Dubbo=(
   "apiDubboRegister"=>"",
   "apiDubboPort"=>"",
   "crmDubboRegister"=>"",
   "crmDubboPort"=>"",
   "mwebDubboRegister"=>"",
   "mwebDubboPort"=>"",
);
our %Report=(
   "reportSender"=>"",
   "reportTempPath"=>"",
   "dailyReportReceiver"=>"",
   "systemReportReceiver"=>""
);
###############################################################################
#Create update log by using module Log::Log4perl
sub readConf(){
   our $section = $ARGV[0]||"performance";
   print "Now section is $section\n";
   my $conf = Config::Tiny->read("./releaseGoldpay.ini");
   if ($conf->{$section} eq ""){
      print "Section doesn't exist, please check out releaseGoldpay.ini to find correct section!\n";
      exit(1);
   }

   $DB{dbHostName}=$conf->{$section}->{dbHostName};
   $DB{gdqDbName}=$conf->{$section}->{gdqDbName};
   $DB{dbUserName}=$conf->{$section}->{dbUserName};
   $DB{dbPassword}=$conf->{$section}->{dbPassword};   

   $Redis{gdqRedisSessionHost}=$conf->{$section}->{gdqRedisSessionHost};
   $Redis{gdqRedisSessionPort}=$conf->{$section}->{gdqRedisSessionPort};
   $Redis{gdqRedisCommonHost}=$conf->{$section}->{gdqRedisCommonHost};
   $Redis{gdqRedisCommonPort}=$conf->{$section}->{gdqRedisCommonPort};
   
  
   $Dubbo{apiDubboRegister}=$conf->{$section}->{apiDubboRegister};
   $Dubbo{apiDubboPort}=$conf->{$section}->{apiDubboPort};
   $Dubbo{crmDubboRegister}=$conf->{$section}->{crmDubboRegister};
   $Dubbo{crmDubboPort}=$conf->{$section}->{crmDubboPort};
   $Dubbo{mwebDubboRegister}=$conf->{$section}->{mwebDubboRegister};
   $Dubbo{mwebDubboPort}=$conf->{$section}->{mwebDubboPort};
   
   $loglevel = $conf->{$section}->{loglevel};
   
   $sendPin = $conf->{$section}->{sendPin};
   $sendEmail = $conf->{$section}->{sendEmail};
   $expire = $conf->{$section}->{expire};

   my $pkgs = $conf->{$section}->{uploadPkgName};
   @pkgs = split(/,/,$pkgs);
 
   my $webAppName = $conf->{$section}->{webAppName};
   @webAppName = split(/,/,$webAppName);
   
   my $srvAppName = $conf->{$section}->{srvAppName};
   @srvAppName = split(/,/,$srvAppName);
   
   if ($section =~/demo/i){
      $buildPath="/home/qa/ProductionPackage/build/gdp/demo";
      system("mkdir $buildPath") unless (-e $buildPath);
   }
   if ($section =~/performance/i){
      $buildPath="/home/qa/ProductionPackage/build/gdp/performance";
      system("mkdir $buildPath") unless (-e $buildPath);
   }
   if ($section =~/production/i){
      $buildPath="/home/qa/ProductionPackage/build/gdp/production";
      system("mkdir $buildPath") unless (-e $buildPath);
   }
   
   $homePath=$conf->{$section}->{homePath};
   $sourcePath=$conf->{$section}->{sourcePath};
   
   $app_Folder{apiFol}=$conf->{$section}->{apiFol};
   $app_Folder{crmFol}=$conf->{$section}->{crmFol};
   $app_Folder{mwebFol}=$conf->{$section}->{mwebFol};
   $app_Folder{oauthFol}=$conf->{$section}->{oauthFol};
   
   $app_logfile{apiLog4jFile}=$conf->{$section}->{apiLog4jFile};
   $app_logfile{crmLog4jFile}=$conf->{$section}->{crmLog4jFile};
   $app_logfile{mwebLog4jFile}=$conf->{$section}->{mwebLog4jFile};
   $app_logfile{oauthLog4jFile}=$conf->{$section}->{oauthLog4jFile};
   
   my @appArr=("api","crm","mweb");
   my @destStr=("destServerIp","destUser","destPass","destPort","destServerPath");
   foreach $appType(@appArr){
      foreach(@destStr){
         $destStr = "$appType"."_"."$_";
         $Dest{$destStr}=$conf->{$section}->{$destStr};
      }
   }
   $Report{reportSender}=$conf->{$section}->{reportSender};
   $Report{reportTempPath}=$conf->{$section}->{reportTempPath};
   $Report{dailyReportReceiver}=$conf->{$section}->{dailyReportReceiver};
   $Report{sysReportReceiver}=$conf->{$section}->{sysReportReceiver};

   $goldqapi_http=$conf->{$section}->{goldqapi_http};
   $goldpay_http=$conf->{$section}->{goldpay_http};

   $testGdpServer=$conf->{$section}->{testGdpServer};
   print "Section:$section\n";
}

sub modifyGlobalConf($;$){
   my ($fileType,$fileName) = @_;
   if ($fileType=~/log4j/i){
      if ($fileName=~/goldqapi/i) {
         system("perl -pi -e 's#log4j.appender.logfile.File\\s*=\\s*(.*).log#log4j.appender.logfile.File=$app_logfile{apiLog4jFile}#' $fileName") if (-e "$fileName");
         #system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=WARN,stdout,logfile#' $fileName") if (-e "$fileName");
         system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=$loglevel,stdout,logfile#' $fileName") if (-e "$fileName");
      }
      if ($fileName=~/goldqcrm/i) {
         system("perl -pi -e 's#log4j.appender.logfile.File\\s*=\\s*(.*).log#log4j.appender.logfile.File=$app_logfile{crmLog4jFile}#' $fileName") if (-e "$fileName");
         #system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=WARN,stdout,logfile#' $fileName") if (-e "$fileName");
         system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=$loglevel,stdout,logfile#' $fileName") if (-e "$fileName");
      }
      if ($fileName=~/goldqmweb/i) {
         system("perl -pi -e 's#log4j.appender.logfile.File\\s*=\\s*(.*).log#log4j.appender.logfile.File=$app_logfile{mwebLog4jFile}#' $fileName") if (-e "$fileName");
         #system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=WARN,stdout,logfile#' $fileName") if (-e "$fileName");
         system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=$loglevel,stdout,logfile#' $fileName") if (-e "$fileName");
      }

      if ($fileName=~/agas/i) {
         system("perl -pi -e 's#log4j.appender.logfile.File\\s*=\\s*(.*).log#log4j.appender.logfile.File=$app_logfile{oauthLog4jFile}#' $fileName") if (-e "$fileName");
         #system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=WARN,stdout,logfile#' $fileName") if (-e "$fileName");
         system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=$loglevel,stdout,logfile#' $fileName") if (-e "$fileName");
      }
   }
   if ($fileType=~/appconf/i){
      `sed -i 's#jdbc.url\\s*=.*#jdbc.url=jdbc:mysql:\/\/$DB{dbHostName}\/$DB{gdqDbName}\?autoReconnect=true\\\&useUnicode=true\\\&characterEncoding=UTF-8#' $fileName` if (-e "$fileName");
      `sed -i 's#goldqapi_http\\s*=.*#goldqapi_http=$goldqapi_http#' $fileName` if (-e "$fileName");
      `sed -i 's#goldpay_http\\s*=.*#goldpay_http=$goldpay_http#' $fileName` if (-e "$fileName");
      `sed -i 's#jdbc.username\\s*=.*#jdbc.username=$DB{dbUserName}#' $fileName` if (-e "$fileName");
      `sed -i 's#jdbc.password\\s*=.*#jdbc.password=$DB{dbPassword}#' $fileName` if (-e "$fileName");
      `sed -i 's#jedis.session.host\\s*=.*#jedis.session.host=$Redis{gdqRedisSessionHost}#' $fileName` if (-e "$fileName");
      `sed -i 's#jedis.session.port\\s*=.*#jedis.session.port=$Redis{gdqRedisSessionPort}#' $fileName` if (-e "$fileName");
      `sed -i 's#jedis.common.host\\s*=.*#jedis.common.host=$Redis{gdqRedisCommonHost}#' $fileName` if (-e "$fileName");
      `sed -i 's#jedis.common.port\\s*=.*#jedis.common.port=$Redis{gdqRedisCommonPort}#' $fileName` if (-e "$fileName");
      #system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=WARN,stdout,logfile#' $fileName") if (-e "$fileName");
   if ($fileName=~/agas/i) {
       `sed -i 's#jdbc.url\\s*=.*#jdbc.url=jdbc:mysql:\/\/$DB{dbHostName}\/prod-agas\?autoReconnect=true\\\&useUnicode=true\\\&characterEncoding=UTF-8#' $fileName` if (-e "$fileName");
   }
   if ($fileName=~/goldqapi/i) {
         `sed -i 's#dubbo.register\\s*=\\s*redis:\/\/.*#dubbo.register=redis:\/\/$Dubbo{apiDubboRegister}#' $fileName` if (-e "$fileName");
         `sed -i 's#dubbo.service.port\\s*=.*#dubbo.service.port=$Dubbo{apiDubboPort}#' $fileName` if (-e "$fileName");
   }
   if ($fileName=~/goldqcrm/i) {
         `sed -i 's#dubbo.register\\s*=\\s*redis:\/\/.*#dubbo.register=redis:\/\/$Dubbo{crmDubboRegister}#' $fileName` if (-e "$fileName");
         `sed -i 's#dubbo.service.port\\s*=.*#dubbo.service.port=$Dubbo{crmDubboPort}#' $fileName` if (-e "$fileName");
         `sed -i 's#sendMail.mailAddress\\s*=.*#sendMail.mailAddress=$Report{reportSender}#' $fileName` if (-e "$fileName");
         `sed -i 's#reportTemp\\s*=.*#reportTemp=$Report{reportTempPath}#' $fileName` if (-e "$fileName");
         `sed -i 's#toMailReport.mailAddress\\s*=.*#toMailReport.mailAddress=$Report{dailyReportReceiver}#' $fileName` if (-e "$fileName");
         `sed -i 's#toMailsysReport.mailAddress\\s*=.*#toMailsysReport.mailAddress=$Report{sysReportReceiver}#' $fileName` if (-e "$fileName");
   }
   if ($fileName=~/goldqmweb/i) {
         `sed -i 's#dubbo.register\\s*=\\s*redis:\/\/.*#dubbo.register=redis:\/\/$Dubbo{mwebDubboRegister}#' $fileName` if (-e "$fileName");
         `sed -i 's#dubbo.service.port\\s*=.*#dubbo.service.port=$Dubbo{mwebDubboPort}#' $fileName` if (-e "$fileName");
         system("perl -pi -e 's#sendPin\\s*=\\s*(.*)#sendPin=$sendPin#g' $fileName") if (-e "$fileName");
         system("perl -pi -e 's#sendEmail\\s*=\\s*(.*)#sendEmail=$sendEmail#g' $fileName") if (-e "$fileName");
         system("perl -pi -e 's#expire\\s*=\\s*(.*)#expire=$expire#g' $fileName") if (-e "$fileName");
         
   }
   }
}

sub modifyAppConf($;$;$){
   my ($fileType,$appType,$app) = @_;
   if ($fileType eq "appconf"){
      if ($appType eq "apache"){
         my $confile="$buildPath/$app/WEB-INF/classes/goldq-conf.properties";
         print "Modify $app config: $confile\n";
         modifyGlobalConf($fileType,$confile);
         if ($app=~/goldqmweb/) {
            my $transfile="$buildPath/$app/WEB-INF/classes/Transfer.properties";
            print "Modify $app config: $transfile\n";
            modifyGlobalConf($fileType,$transfile); 
         }
         if ($app=~/agas/) {
            my $agasfile="$buildPath/$app/WEB-INF/classes/agas-conf.properties";
            print "Modify $app config: $agasfile agas-conf1111\n";
            modifyGlobalConf($fileType,$agasfile);
         }    
        
      }
   }elsif($fileType eq "log4j"){
      if ($appType eq "apache"){
         my $confile="$buildPath/$app/WEB-INF/classes/log4j.properties";
         print "Modify $app config: $confile\n";
         modifyGlobalConf($fileType,$confile);
         
         
      } 
   }
}
   
sub copy2ProductDir(){
   print "--------Start to copy package-------\n";
   my $app=shift;
   chdir("$buildPath");
   my $rsyncTagName = "DeploymentHome";
   #Create new fold to store backup files if folders don't exist.
   system("mkdir $app_Folder{apiFol}") unless (-e "$app_Folder{apiFol}");
   system("mkdir $app_Folder{crmFol}") unless (-e "$app_Folder{crmFol}");
   system("mkdir $app_Folder{mwebFol}") unless (-e "$app_Folder{mwebFol}");
   system("mkdir $app_Folder{oauthFol}") unless (-e "$app_Folder{oauthFol}");
   
   #Clean all folders.
   system ("rm -rf $app_Folder{apiFol}/* $app_Folder{crmFol}/* $app_Folder{mwebFol}/* $app_Folder{oauthFol}/*");

   system("rsync -vzrtopg --delete --progress qa\@$testGdpServer"."::"."$rsyncTagName/apache-tomcat/webapps/$app_Folder{apiFol}/ $buildPath/$app_Folder{apiFol}/");
   system("rsync -vzrtopg --delete --progress qa\@$testGdpServer"."::"."$rsyncTagName/apache-tomcat/webapps/$app_Folder{crmFol}/ $buildPath/$app_Folder{crmFol}/");
   system("rsync -vzrtopg --delete --progress qa\@$testGdpServer"."::"."$rsyncTagName/apache-tomcat/webapps/$app_Folder{mwebFol}/ $buildPath/$app_Folder{mwebFol}/");
   system("rsync -vzrtopg --delete --progress qa\@$testGdpServer"."::"."$rsyncTagName/apache-tomcat/webapps/$app_Folder{oauthFol}/ $buildPath/$app_Folder{oauthFol}/");
   
}

sub createPkg(){
   chdir("$buildPath");
   print "Create tar package for each app...\n";
   foreach(@pkgs){
      if($_=~/goldqapi/i){
         system("tar -zcf goldqapi.tar.gz ./goldqapi");   
      }
      if($_=~/goldqcrm/i){
         system("tar -zcf goldqcrm.tar.gz ./goldqcrm");    
      }
      if($_=~/goldqmweb/i){                 
         system("tar -zcf goldqmweb.tar.gz ./goldqmweb");
      }
      if($_=~/agas/i){
         system("tar -zcf agas.tar.gz ./agas");
      }
   }
    
   print "Backup packages to $homePath/bak/gdp/$section folder...\n";
   delExpireBak(30); #delete bak file expire 30 days.
   my $time=`date +%Y-%m-%d`;
   chomp($time);
   my @tar = glob "$buildPath/*.tar.gz";
   foreach(@tar){
      $_ = ~/$buildPath\/(.*)\.tar\.gz/;
      my $file=$1;
      #print "tar = $_\n pkg = $file\n";
      print "pkg = $file\n";
      system("cp -f $buildPath/$file.tar.gz $homePath/bak/gdp/$section/$file-$time.tar.gz");    
   }
}

sub delExpireBak($){
   my $expire = shift; #Unit:day
   $expire = $expire*24*60*60;
   my @files = glob("$homePath/bak/gdp/$section*");
   foreach(@files){
      if(time()-(stat($_))[9]>$expire){
         print "Delete file $_\n";
         unlink($_);
      }
   }
}

sub uploadPkg(){
   chdir("$buildPath");
   foreach(@pkgs){
      if($_=~/goldqapi/i){
         print "--------Start to upload $_ package-------\n";
         system("pscp -pw $Dest{api_destPass} -P $Dest{api_destPort} ./goldqapi.tar.gz $Dest{api_destUser}\@$Dest{api_destServerIp}:/$Dest{api_destServerPath}/");
      }
      if($_=~/goldqcrm/i){
         print "--------Start to upload $_ package-------\n";
         system("pscp -pw $Dest{crm_destPass} -P $Dest{crm_destPort} ./goldqcrm.tar.gz $Dest{crm_destUser}\@$Dest{crm_destServerIp}:/$Dest{crm_destServerPath}/");
      }
      if($_=~/goldqmweb/i){
         print "--------Start to upload $_ package-------\n";
         system("pscp -pw $Dest{mweb_destPass} -P $Dest{mweb_destPort} ./goldqmweb.tar.gz $Dest{mweb_destUser}\@$Dest{mweb_destServerIp}:/$Dest{mweb_destServerPath}/");
      }
      if($_=~/agas/i){
         print "--------Start to upload $_ package-------\n";
         system("pscp -pw $Dest{mweb_destPass} -P $Dest{mweb_destPort} ./agas.tar.gz $Dest{mweb_destUser}\@$Dest{mweb_destServerIp}:/$Dest{mweb_destServerPath}/");
      }
   }


      if ($section eq "production"){
   	 print "Backup packages to S3 on AWS\n";
   	 system("s3cmd --delete-removed sync $homePath/bak/gdp/$section/ s3://aspectgaming-databackup/pkg/goldpay/");
      }
}

####################################################################
	readConf();
	print "Do you want to copy package to ProductionPackage dir?[y/n]";
	chomp($result = <STDIN>);
	$result=lc($result);
	if ($result eq "y"){
   		print "start copying\n";
   		copy2ProductDir();
	}
	print "Do you want to modify configuration and build tar packages?(y/n)";
	chomp($result = <STDIN>);
	$result = lc($result);
	if ($result eq "y"){
   	foreach(@webAppName){
      		modifyAppConf('appconf','apache',$_);
      		modifyAppConf('log4j','apache',$_);
   	}
   		createPkg();
	}

	print "Do you want to upload packages to servers?(y/n)";
	chomp($result = <STDIN>);
	$result = lc($result);
	if ($result eq "y"){
   		uploadPkg();
	}
