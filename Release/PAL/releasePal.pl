#!/usr/bin/perl -w
#use strict;
use Log::Log4perl;
use Config::Tiny;

our $buildPath;
our @pkgs=();
our @webAppName=();
our @srvAppName=();
our ($homePath,$sourcePath);
our ($mkl_serverip_port);


our %mklws_Dest=(
   "mklws_destServerIp"=>"",
   "mklws_destServerPath"=>"",
   "mklws_destUser"=>"",
   "mklws_destPass"=>"",
   "mklws_destPort"=>""
);

our %mklcmsj_Dest=(
   "mklcmsj_destServerIp"=>"",
   "mklcmsj_destServerPath"=>"",
   "mklcmsj_destUser"=>"",
   "mklcmsj_destPass"=>"",
   "mklcmsj_destPort"=>""
);

our %DB=(
   "dbHostName"=>"",
   "gdqDbName"=>"",
   "mklDbName"=>"",
   "dbUserName"=>"",
   "dbPassword"=>""   
);

our %Redis=(
   "mklRedisSessionHost"=>"",
   "mklRedisSessionPort"=>"",
   "mklRedisCommonHost"=>"",
   "mklRedisCommonPort"=>""
);

our %Dubbo=(
   "cmsjDubboRegister"=>"",
   "cmsjDubboPort"=>""
);
###############################################################################
#Create update log by using module Log::Log4perl
sub readConf(){
   our $section = $ARGV[0]||"production";
   my $conf = Config::Tiny->read("./releasePal.ini");
   if ($conf->{$section} eq ""){
      print "Section doesn't exist, please check out releasePal.ini to find correct section!\n";
      exit(1);
   }

   $DB{dbHostName}=$conf->{$section}->{dbHostName};
   $DB{gdqDbName}=$conf->{$section}->{gdqDbName};
   $DB{mklDbName}=$conf->{$section}->{mklDbName};
   $DB{dbUserName}=$conf->{$section}->{dbUserName};
   $DB{dbPassword}=$conf->{$section}->{dbPassword};   

   
   $Redis{mklRedisSessionHost}=$conf->{$section}->{mklRedisSessionHost};
   $Redis{mklRedisSessionPort}=$conf->{$section}->{mklRedisSessionPort};
   $Redis{mklRedisCommonHost}=$conf->{$section}->{mklRedisCommonHost};
   $Redis{mklRedisCommonPort}=$conf->{$section}->{mklRedisCommonPort};   
  
   $Dubbo{cmsjDubboRegister}=$conf->{$section}->{cmsjDubboRegister};
   $Dubbo{cmsjDubboPort}=$conf->{$section}->{cmsjDubboPort};

   #$Dubbo{webDubboRegister}=$conf->{$section}->{webDubboRegister};
   #$Dubbo{webDubboPort}=$conf->{$section}->{webDubboPort};   

   $loglevel = $conf->{$section}->{loglevel};

   my $pkgs = $conf->{$section}->{uploadPkgName};
   @pkgs = split(/,/,$pkgs);
 
   my $webAppName = $conf->{$section}->{webAppName};
   @webAppName = split(/,/,$webAppName);
   
   my $srvAppName = $conf->{$section}->{srvAppName};
   @srvAppName = split(/,/,$srvAppName);
   
   if ($section =~/demo/i){
      $buildPath="/home/qa/ProductionPackage/build/pal/demo";
      system("mkdir $buildPath") unless (-e $buildPath);
   }
   if ($section =~/performance/i){
      $buildPath="/home/qa/ProductionPackage/build/pal/performance";
      system("mkdir $buildPath") unless (-e $buildPath);
   }
   if ($section =~/production/i){
      $buildPath="/home/qa/ProductionPackage/build/pal/production";
      system("mkdir $buildPath") unless (-e $buildPath);
   }
   
   $homePath=$conf->{$section}->{homePath};
   $sourcePath=$conf->{$section}->{sourcePath};
   
   $QN_http=$conf->{$section}->{QN_http};
   $QN_bucketName=$conf->{$section}->{QN_bucketName};
   
   $httpPort=$conf->{$section}->{httpport};

   $app_Folder{mklwsFol}=$conf->{$section}->{mklwsFol};
   $app_Folder{cmsjFol}=$conf->{$section}->{cmsjFol};
   $app_Folder{webFol}=$conf->{$section}->{webFol};  
   $app_Folder{clientFol}=$conf->{$section}->{clientFol};  
   $app_Folder{wechatFol}=$conf->{$section}->{wechatFol};
   $app_logfile{cmsjLog4jFile}=$conf->{$section}->{cmsjLog4jFile};
   $app_logfile{webLog4jFile}=$conf->{$section}->{webLog4jFile};  
 
   $ws_log_level = $conf->{$section}->{ws_log_level};
   $ws_show_sql = $conf->{$section}->{ws_show_sql};

   $AppKey = $conf->{$section}->{AppKey};
   $Secret  = $conf->{$section}->{Secret};
   
   my @appArr=("mklws","mklcmsj","mklweb");
   my @destStr=("destServerIp","destUser","destPass","destPort","destServerPath");
   foreach $appType(@appArr){
      foreach(@destStr){
         $destStr = "$appType"."_"."$_";
         $Dest{$destStr}=$conf->{$section}->{$destStr};
      }
   }
   $mkl_serverip_port=$conf->{$section}->{mkl_serverip_port};
   $serverHttp = $conf->{$section}->{serverHttp};
   $clientId = $conf->{$section}->{clientId};
   $serverUrl = $conf->{$section}->{serverUrl};
   $app_ID = $conf->{$section}->{app_ID};
   $app_KEY = $conf->{$section}->{app_KEY};
   $redirect_URI = $conf->{$section}->{redirect_URI};

   $ggaTrackId = $conf->{$section}->{ggaTrackId};
   $hm_src = $conf->{$section}->{hm_src};


   $testPalServer = $conf->{$section}->{testPalServer};

   print "Section:$section\n";

}

sub modifyGlobalConf($;$){
   my ($fileType,$fileName) = @_;
   if ($fileType=~/log4j/i){
      if ($fileName=~/cms/i) {
         system("perl -pi -e 's#log4j.appender.logfile.File\\s*=\\s*(.*).log#log4j.appender.logfile.File=$app_logfile{cmsjLog4jFile}#' $fileName") if (-e "$fileName");
         system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=$loglevel,stdout,logfile#' $fileName") if (-e "$fileName");
      }
      if ($fileName=~/web\/WEB-INF/i) {
	 print "修改LOG4J\n";
         system("perl -pi -e 's#log4j.appender.logfile.File\\s*=\\s*(.*).log#log4j.appender.logfile.File=$app_logfile{webLog4jFile}#' $fileName") if (-e "$fileName");
         system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=$loglevel,stdout,logfile#' $fileName") if (-e "$fileName");
      }  
	if ($fileName=~/client\/WEB-INF/i) {
         system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=$loglevel,stdout,logfile#' $fileName") if (-e "$fileName");
      } 
	if ($fileName=~/wechat\/WEB-INF/i) {
         system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=$loglevel,stdout,logfile#' $fileName") if (-e "$fileName");
      }
   }
   if ($fileType=~/appconf/i){
      `sed -i 's#jdbc.url\\s*=.*#jdbc.url=jdbc:mysql:\/\/$DB{dbHostName}\/$DB{mklDbName}\?autoReconnect=true\\\&useUnicode=true\\\&characterEncoding=UTF-8#' $fileName` if (-e "$fileName");
      `sed -i 's#jdbc.username\\s*=.*#jdbc.username=$DB{dbUserName}#' $fileName` if (-e "$fileName");
      `sed -i 's#jdbc.password\\s*=.*#jdbc.password=$DB{dbPassword}#' $fileName` if (-e "$fileName");
      `sed -i 's#jedis.session.host\\s*=.*#jedis.session.host=$Redis{mklRedisSessionHost}#' $fileName` if (-e "$fileName");
      `sed -i 's#jedis.session.port\\s*=.*#jedis.session.port=$Redis{mklRedisSessionPort}#' $fileName` if (-e "$fileName");
      `sed -i 's#jedis.common.host\\s*=.*#jedis.common.host=$Redis{mklRedisCommonHost}#' $fileName` if (-e "$fileName");
      `sed -i 's#jedis.common.port\\s*=.*#jedis.common.port=$Redis{mklRedisCommonPort}#' $fileName` if (-e "$fileName");
      `sed -i 's#QN_http\\s*=.*#QN_http=$QN_http#' $fileName` if (-e "$fileName");
      `sed -i 's#QN_bucketName\\s*=.*#QN_bucketName=$QN_bucketName#' $fileName` if (-e "$fileName");
      ####for mkl_ws/conf/config.ini####
      `sed -i 's#session_data_server\\s*=.*#session_data_server =$Redis{mklRedisSessionHost}:$Redis{mklRedisSessionPort}#' $fileName` if (-e "$fileName");
      `sed -i 's#db.dbname\\s*=.*#db.dbname=$DB{mklDbName}#' $fileName` if (-e "$fileName");
      `sed -i 's#db.user\\s*=.*#db.user=$DB{dbUserName}#' $fileName` if (-e "$fileName");
      `sed -i 's#db.password\\s*=.*#db.password=$DB{dbPassword}#' $fileName` if (-e "$fileName");
      `sed -i 's#db.host\\s*=.*#db.host=$DB{dbHostName}#' $fileName` if (-e "$fileName");
      `sed -i 's#goldq.db.dbname\\s*=.*#goldq.db.dbname=$DB{gdqDbName}#' $fileName` if (-e "$fileName");
      `sed -i 's#goldq.db.user\\s*=.*#goldq.db.user=$DB{dbUserName}#' $fileName` if (-e "$fileName");
       `sed -i 's#goldq.db.password\\s*=.*#goldq.db.password=$DB{dbPassword}#' $fileName` if (-e "$fileName");
      `sed -i 's#goldq.db.host\\s*=.*#goldq.db.host=$DB{dbHostName}#' $fileName` if (-e "$fileName");
      `sed -i 's#http.port\\s*=.*#http.port=$httpPort#' $fileName` if (-e "$fileName");
      `sed -i 's#ws_log_level\\s*=.*#ws_log_level=$ws_log_level#' $fileName` if (-e "$fileName");
      `sed -i 's#ws_show_sql\\s*=.*#ws_show_sql=$ws_show_sql#' $fileName` if (-e "$fileName");

       ########for /srv/mkl-server/mkl_ws/src/common/consts/consts.go ####
       `sed -i 's#AppKey\\s*=.*#AppKey = $AppKey#' $fileName` if (-e "$fileName");
       `sed -i 's#Secret\\s*=.*#Secret = $Secret#' $fileName` if (-e "$fileName");
      #system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=WARN,stdout,logfile#' $fileName") if (-e "$fileName");
   if ($fileName=~/cms/i) {
         system("perl -pi -e 's#SERVER_HTTP\\s*=\\s*(.*)#SERVER_HTTP=$mkl_serverip_port#g' $fileName") if (-e "$fileName");
	 `sed -i 's#dubbo.register\\s*=\\s*redis:\/\/.*#dubbo.register=redis:\/\/$Dubbo{cmsjDubboRegister}#' $fileName` if (-e "$fileName");
	 `sed -i 's#dubbo.service.port\\s*=.*#dubbo.service.port=$Dubbo{cmsjDubboPort}#' $fileName` if (-e "$fileName");
   }
   
   if ($fileName=~/web\/WEB-INF/i) {
         system("perl -pi -e 's#SERVER_HTTP\\s*=\\s*(.*)#SERVER_HTTP=$serverHttp#g' $fileName") if (-e "$fileName");
         #`sed -i 's#dubbo.register\\s*=\\s*redis:\/\/.*#dubbo.register=redis:\/\/$Dubbo{webDubboRegister}#' $fileName` if (-e "$fileName");
         #`sed -i 's#dubbo.service.port\\s*=.*#dubbo.service.port=$Dubbo{webDubboPort}#' $fileName` if (-e "$fileName");
   }
   
   if ($fileName=~/web\/js/i) {
	 `sed -i 's#var\\s*clientId\\s*=.*#var clientId = \'$clientId\';#' $fileName` if (-e "$fileName");
	 `sed -i 's#var\\s*serverUrl\\s*=.*#var serverUrl = \'$serverUrl\';#' $fileName` if (-e "$fileName");
   }
  
   if ($fileName=~/client\/js/i) {
         `sed -i "s#clientID\\s*=.*#clientID = '$clientId';#" $fileName` if (-e "$fileName");
         `sed -i "s#serverUrl\\s*=.*#serverUrl = '$serverUrl';#" $fileName` if (-e "$fileName");
   }

   if ($fileName=~/client\/index\.html/i) {
	 `sed -i "s#ga('create', .*, 'auto')#ga('create', '$ggaTrackId', 'auto')#" $fileName` if (-e "$fileName");
         `sed -i 's#hm.src\\s*=.*#hm.src = "$hm_src";#' $fileName` if (-e "$fileName");
   }
   if ($fileName=~/client\/WEB-INF/i) {
	`sed -i 's#SERVER_HTTP\\s*=.*#SERVER_HTTP = $serverHttp#' $fileName` if (-e "$fileName");
	`sed -i 's#clientID\\s*=.*#clientID = $clientId#' $fileName` if (-e "$fileName");
	`sed -i 's#app_ID\\s*=.*#app_ID = $app_ID#' $fileName` if (-e "$fileName");
	`sed -i 's#app_KEY\\s*=.*#app_KEY = $app_KEY#' $fileName` if (-e "$fileName");
	`sed -i 's#redirect_URI\\s*=.*#redirect_URI = $redirect_URI#' $fileName` if (-e "$fileName");
   }

   if ($fileName=~/wechat\/WEB-INF/i) {
        `sed -i 's#SERVER_HTTP\\s*=.*#SERVER_HTTP = $serverHttp#' $fileName` if (-e "$fileName");
        `sed -i 's#clientID\\s*=.*#clientID = $clientId#' $fileName` if (-e "$fileName");
        `sed -i 's#app_ID\\s*=.*#app_ID = $app_ID#' $fileName` if (-e "$fileName");
        `sed -i 's#app_KEY\\s*=.*#app_KEY = $app_KEY#' $fileName` if (-e "$fileName");
        `sed -i 's#redirect_URI\\s*=.*#redirect_URI = $redirect_URI#' $fileName` if (-e "$fileName");
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
        
      }elsif($appType eq "mklws"){
         my $confile="$buildPath/$app/conf/config.ini";
         print "Modify $app config:$confile\n";
         modifyGlobalConf($fileType,$confile);
	 my $confile_go = "$buildPath/$app/src/common/consts/consts.go";
	 print "Modify $app config:$confile_go\n";
	 modifyGlobalConf($fileType,$confile_go);
      }elsif($appType eq "webJs"){
	 my $confile="$buildPath/$app/js/facebookparam.js";
	 print "Modify $app config:$confile\n";
	 modifyGlobalConf($fileType,$confile);
      }elsif($appType eq "clientJs"){
         my $confile="$buildPath/$app/js/t-functions.js";
         print "Modify $app config:$confile\n";
         modifyGlobalConf($fileType,$confile);
      }elsif($appType eq "clientIndex"){
         my $confile="$buildPath/$app/index.html";
         print "Modify $app config:$confile\n";
         modifyGlobalConf($fileType,$confile);
      }elsif($appType eq "qqconn"){
	 my $confile="$buildPath/$app/WEB-INF/classes/qqconnectconfig.properties";
         print "Modify $app config:$confile\n";
	 modifyGlobalConf($fileType,$confile);
      }
   }elsif($fileType eq "log4j"){
      if ($appType eq "apache"){
         my $confile="$buildPath/$app/WEB-INF/classes/log4j.properties";
         print "Modify $app config: $confile\n";
         modifyGlobalConf($fileType,$confile);
         
         
      } 
   }
}
   
sub rsyncProductDir(){
   print "--------Start to copy package-------\n";
   my $app=shift;
   chdir("$buildPath");
   my $rsyncTagName = "DeploymentHome";
   #Create new fold to store backup files if folders don't exist.
   system("mkdir $app_Folder{mklwsFol}") unless (-e "$app_Folder{mklwsFol}");
   system("mkdir $app_Folder{cmsjFol}") unless (-e "$app_Folder{cmsjFol}");
   system("mkdir $app_Folder{webFol}") unless (-e "$app_Folder{webFol}");
   system("mkdir $app_Folder{clientFol}") unless (-e "$app_Folder{clientFol}");
   system("mkdir $app_Folder{wechatFol}") unless (-e "$app_Folder{wechatFol}");
   #Clean all folders.
   system("rm -rf $app_Folder{mklwsFol}/*  $app_Folder{cmsjFol}/*  $app_Folder{webFol}/* $app_Folder{clientFol}/* $app_Folder{wechatFol}/* ");
   

   system("rsync -vzrtopg --delete --progress qa\@$testPalServer"."::"."$rsyncTagName/mkl-server/$app_Folder{mklwsFol}/ $buildPath/$app_Folder{mklwsFol}/");
   system("rsync -vzrtopg --delete --progress qa\@$testPalServer"."::"."$rsyncTagName/apache-tomcat/webapps/$app_Folder{cmsjFol}/ $buildPath/$app_Folder{cmsjFol}/");
   system("rsync -vzrtopg --delete --progress qa\@$testPalServer"."::"."$rsyncTagName/apache-tomcat/webapps/$app_Folder{webFol}/ $buildPath/$app_Folder{webFol}/");
   system("rsync -vzrtopg --delete --progress qa\@$testPalServer"."::"."$rsyncTagName/apache-tomcat/webapps/$app_Folder{clientFol}/ $buildPath/$app_Folder{clientFol}/");
   system("rsync -vzrtopg --delete --progress qa\@$testPalServer"."::"."$rsyncTagName/apache-tomcat/webapps/$app_Folder{wechatFol}/ $buildPath/$app_Folder{wechatFol}/");

}

sub createPkg(){
   chdir("$buildPath");
   print "Create tar package for each app...\n";
   foreach(@pkgs){
      if($_=~/mkl_ws/i){
         print "Build wsapp before create tar package\n";
         system("chmod +x $buildPath/$_/install*");
         system("./$app_Folder{mklwsFol}/install_qa.rb ");
         system("tar -zcf mkl_ws.tar.gz ./mkl_ws");    
      }
      if($_=~/cms/i){
         system("tar -zcf cms.tar.gz ./cms");    
      }
      if($_=~/web/i){
         system("tar -zcf web.tar.gz ./web");
      }
      if($_=~/client/i){
         system("tar -zcf client.tar.gz ./client");
      }
      if($_=~/wechat/i){
         system("tar -zcf wechat.tar.gz ./wechat");
      }
   }
    
   print "Backup packages to $homePath/bak/pal/$section folder...\n";
   delExpireBak(30); #delete bak file expire 30 days.
   my $time=`date +%Y-%m-%d`;
   chomp($time);
   my @tar = glob "$buildPath/*.tar.gz";
   foreach(@tar){
      $_ = ~/$buildPath\/(.*)\.tar\.gz/;
      my $file=$1;
      #print "tar = $_\n pkg = $file\n";
      print "pkg = $file\n";
      system("cp -f $buildPath/$file.tar.gz $homePath/bak/pal/$section/$file-$time.tar.gz");    
   }
}

sub delExpireBak($){
   my $expire = shift; #Unit:day
   $expire = $expire*24*60*60;
   my @files = glob("$homePath/bak/pal/$section*");
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
      if($_=~/mkl_ws/i){
         print "--------Start to upload $_ package-------\n";
         system("pscp -pw $Dest{mklws_destPass} -P $Dest{mklws_destPort} ./mkl_ws.tar.gz $Dest{mklws_destUser}\@$Dest{mklws_destServerIp}:/$Dest{mklws_destServerPath}/");
      }
      if($_=~/cms/i){
         print "--------Start to upload $_ package-------\n";
         system("pscp -pw $Dest{mklcmsj_destPass} -P $Dest{mklcmsj_destPort} ./cms.tar.gz $Dest{mklcmsj_destUser}\@$Dest{mklcmsj_destServerIp}:/$Dest{mklcmsj_destServerPath}/");
      }
      if($_=~/web/i){
         print "--------Start to upload $_ package-------\n";
         system("pscp -pw $Dest{mklweb_destPass} -P $Dest{mklweb_destPort} ./web.tar.gz $Dest{mklweb_destUser}\@$Dest{mklweb_destServerIp}:/$Dest{mklweb_destServerPath}/");
      }

      if($_=~/client/i){
         print "--------Start to upload $_ package-------\n";
         system("pscp -pw $Dest{mklweb_destPass} -P $Dest{mklweb_destPort} ./client.tar.gz $Dest{mklweb_destUser}\@$Dest{mklweb_destServerIp}:/$Dest{mklweb_destServerPath}/");
      }

      if($_=~/wechat/i){
         print "--------Start to upload $_ package-------\n";
         system("pscp -pw $Dest{mklweb_destPass} -P $Dest{mklweb_destPort} ./wechat.tar.gz $Dest{mklweb_destUser}\@$Dest{mklweb_destServerIp}:/$Dest{mklweb_destServerPath}/");
      }

   }
      if ($section eq "production"){
   	 print "Backup packages to S3 on AWS\n";
   	 system("s3cmd --delete-removed sync $homePath/bak/pal/$section/ s3://aspectgaming-databackup/pkg/pal/");
      }

}

####################################################################
if ((@ARGV == 0)||(@ARGV == 1)) {
	readConf();
	print "Do you want to rsync package to ProductionPackage/build/pal/ dir?[y/n]";
	chomp($result = <STDIN>);
	$result=lc($result);
	if ($result eq "y"){
   		print "start copying\n";
   		rsyncProductDir();
	}

	print "Do you want to modify configuration and build tar packages?(y/n)";
	chomp($result = <STDIN>);
	$result = lc($result);
	if ($result eq "y"){
   		foreach(@webAppName){
      			modifyAppConf('appconf','apache',$_);
			modifyAppConf('appconf','webJs',$_);
			modifyAppConf('appconf','qqconn',$_);
			modifyAppConf('appconf','clientJs',$_);
			modifyAppConf('appconf','clientIndex',$_);
      			modifyAppConf('log4j','apache',$_);
   		}
   		foreach(@srvAppName){
      			modifyAppConf('appconf','mklws',$_);
   		}
   		createPkg();
	}	

	print "Do you want to upload packages to servers?(y/n)";
	chomp($result = <STDIN>);
	$result = lc($result);
	if ($result eq "y"){
   		uploadPkg();
	}
}else{
	print "Usage: $0\n";
	print "       $0 section\n";
}
