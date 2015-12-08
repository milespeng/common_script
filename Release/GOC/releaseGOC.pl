#!/usr/bin/perl -w
#use strict;
####################################################
#   Created by william on Feb 26 2013
#   Purpose: Create production package from testing environment
#   Install scripts in task server
#   Change Logs:
#   Apr 23 2013
#       Add read config fuction
#   May 13 2013
#        Integrate ML and FB project, Scripts has be separately installed in 10.1.1.60(ML) and 54.251.40.72(FB);
#
#   Oct 12 2013
#       Add hadoop configuration and data tacker server;
#
#   Mar 27 2014
#       Support release for online game;
#   Jul 16 2014
#       Only create GOC_Web packages to prodution
####################################################
use Config::Tiny;
our $result;
our $version="200";
our @redis=();
our @pkgs=();
our ($MLSRV,$MLAPI,$platform,$compressAmf,$isTesting,$appID,$appSecret,$appName,$appDomain);
our ($redisGlobal,$redisPlayer,$redisQueue,$redisSession);
our ($DBIP,$gameServerIP,$pokerSrvIP,$cobarIP,$taskServerIP,$logServerIP,$bossServerIP);
#Hadoop arguments
our ($zookeeperQuorum,$hiveIP);
our ($dumpTime,$coldTime,$dumpTrigger);
#Path create build on local;
our $buildPath;
# Source IP;
our %SIP=(
    "SVN"=>"",
    "gameServer"=>"",
    "manageServer"=>"",
    "pokerSrv"=>"",
    "site"=>"",
);
# need to upload package
#gameSrv,client,bossSrv,logSrv,taskSrv,pokerSrv,trackSrv,gameSite
our %isUpload=(
    "gameSrv"=>"false",
    "client"=>"false",
    "bossSrv"=>"false",
    "logSrv"=>"false",
    "taskSrv"=>"false",
    "pokerSrv"=>"false",
    "trackSrv"=>"false",
    "gameSite"=>"false",
);
#Source Path;
our %SPath=(
    "home"=>"/home/qa/ProductionPackage",
    "gameServer"=>"/srv/apache-tomcat/webapps/gameserver",
    "client"=>"/srv/apache-tomcat/webapps/client",
    "taskServer"=>"/srv/taskserver",
    "logServer"=>"/srv/apache-tomcat/webapps/logserver",
    "pokerSrv"=>"/srv/pokerserver",
    "bossServer"=>"/srv/apache-tomcat/webapps/bossserver",
    "trackSrv"=>"/srv/apache-tomcat/webapps/trackserver",
    "flash"=>"/srv/apache-tomcat/webapps/onlineGameFlash",
    "gameSite"=>"/srv/gamessite",
    "SVN"=>"",
);

#Destination Path;
our %DPath=(
    #"puppet"=>"/etc/puppet/files/production/resource",
    "server"=>"",
    "client"=>"",
    "user"=>"",
    "pwd"=>"",
    "port"=>""
);

sub readConf(){
    our $section = $ARGV[0]||"goc";
    my $conf = Config::Tiny->read("releaseGOC.ini");
    if ($conf->{$section} eq ""){
        print "Section doesn't exist, please check out createPP.ini to find correct section!\n";
        exit(1);
    }
    $SIP{SVN}=$conf->{$section}->{SVNIP};
    $SPath{SVN}=$conf->{$section}->{SVNPath};
    $SIP{gameServer}=$conf->{$section}->{sourceGameServerIP};
    $SIP{manageServer}=$conf->{$section}->{sourceManageServerIP};
    $SIP{pokerSrv}=$conf->{$section}->{sourcePokerServerIP};
    
    my $pkgs = $conf->{$section}->{uploadPkgName};
    @pkgs = split(/,/,$pkgs);
    $DPath{server}=$conf->{$section}->{uploadServerPath};
    $DPath{client}=$conf->{$section}->{uploadClientPath};
    $DPath{user}=$conf->{$section}->{user};
    $DPath{pwd}=$conf->{$section}->{password};
    $DPath{port}=$conf->{$section}->{port};  
    
    $compressAmf=$conf->{$section}->{compressAmf};
    $isTesting=$conf->{$section}->{isTesting};
    $MLAPI=$conf->{$section}->{makeLivingAPI};
    $MLSRV=$conf->{$section}->{makeLivingSrv};
    $appID=$conf->{$section}->{appID};
    $appName=$conf->{$section}->{appName};
    $appSecret=$conf->{$section}->{appSecret};
    $appDomain=$conf->{$section}->{appDomain};
    
    $redisGlobal=$conf->{$section}->{redisGlobal};
    $redisPlayer=$conf->{$section}->{redisPlayer};
    $redisQueue=$conf->{$section}->{redisQueue};
    $redisSession=$conf->{$section}->{redisSession};
    
    $DBIP=$conf->{$section}->{DBIP};
    $gameServerIP=$conf->{$section}->{gameServerIP};
    $pokerSrvIP=$conf->{$section}->{pokerServerIP};
    $cobarIP=$conf->{$section}->{cobarIP};
    $taskServerIP=$conf->{$section}->{taskServerIP};
    $logServerIP=$conf->{$section}->{logServerIP};
    $bossServerIP=$conf->{$section}->{bossServerIP};
    
    $dumpTime=$conf->{$section}->{redisDumpTime};
    $coldTime=$conf->{$section}->{redisColdTime};
    $dumpTrigger=$conf->{$section}->{playerDataDumpTrigger};
    
    $zookeeperQuorum=$conf->{$section}->{zookeeperQuorum};
    $hiveIP=$conf->{$section}->{hiveIP};
    
    $buildPath = "/home/qa/ProductionPackage/build/$section";
    #Create build folder if the folder doesn't exist.
    system("mkdir -p /home/qa/ProductionPackage/build/$section") unless (-e "/home/qa/ProductionPackage/build/$section");
    
    if($section=~/gli/i){
    	$SIP{pokerSrv}=$conf->{$section}->{sourceGamessiteIP};
    }
    
    print "Section:$section\n";

    ####shell.html ggaLogServer and ggaTrackId ######
    #$ggaLogServer=$conf->{$section}->{ggaLogServer};
    #$ggaTrackId=$conf->{$section}->{ggaTrackId};
    $writeKey=$conf->{$section}->{writeKey};

}


sub getFiles(){
    #system("rm -fR $SPath{home}/build/*");
    my $rsyncTagName = "DeploymentHome";
    foreach(@pkgs){
        if($_=~/gameSrv/i){
            system("rsync -vzrtopg --delete --progress qa\@$SIP{gameServer}::$rsyncTagName/apache-tomcat/webapps/gameserver/ $buildPath/gameserver/");
        }
        if($_=~/client/i){
            system("rsync -vzrtopg --delete --progress qa\@$SIP{gameServer}::$rsyncTagName/apache-tomcat/webapps/client/ $buildPath/client/");    
        }
        if($_=~/pokerSrv/i){
            system("rsync -vzrtopg --delete --progress qa\@$SIP{gameServer}::$rsyncTagName/pokerserver/ $buildPath/pokerserver/");
        }
        if($_=~/bossSrv/i){
            system("rsync -vzrtopg --delete --progress qa\@$SIP{manageServer}::$rsyncTagName/apache-tomcat/webapps/bossserver/ $buildPath/bossserver/");
        }
        if($_=~/logSrv/i){
            system("rsync -vzrtopg --delete --progress qa\@$SIP{manageServer}::$rsyncTagName/apache-tomcat/webapps/logserver/ $buildPath/logserver/");
        }
        if($_=~/taskSrv/i){
            system("rsync -vzrtopg --delete --progress qa\@$SIP{manageServer}::$rsyncTagName/taskserver/ $buildPath/taskserver/");
        }
        if($_=~/trackSrv/i){
            system("rsync -vzrtopg --delete --progress qa\@$SIP{manageServer}::$rsyncTagName/apache-tomcat/webapps/trackserver/ $buildPath/trackserver/");
        }
        if($_=~/gameSite/i){
            system("cp -fR $SPath{gameSite} $buildPath")
        }
    }
    getProductionConf();
    
    #Compare properties files between before and after
    #chdir("$SPath{home}/conf");
    #my @confs=("game-conf","task-conf","log-conf","boss-conf");
    #foreach(@confs){
    #    print "diff $_.properties ./$_-bak.properties\n";
    #    $result=`diff ./$_.properties ./$_-bak.properties` ;
    #    if($result=~/\w+/){
    #        print "Starting to back $_ file...\n";
    #        system("cp -f ./$_.properties ./$_-bak.properties"); 
    #    }          
    #}
}
sub getProductionConf(){
    print "Copy $section configuration to build\n";
    if($section=~/^goc\d?$/i){
        #print "pscp -pw aspect -r qa\@$SIP{SVN}:$SPath{SVN}/gameserver/src/main/resources/production/*.$_ $SPath{home}/\n";
        system("cp -f $SPath{SVN}/gameserver/src/main/resources/production/* $buildPath/gameserver/WEB-INF/classes/");
        system("cp -f $SPath{SVN}/taskserver/src/main/resources/production/* $buildPath/taskserver/conf/");
        system("cp -f $SPath{SVN}/logserver/src/main/resources/production/* $buildPath/logserver/WEB-INF/classes/");  
        system("cp -f $SPath{SVN}/bossserver/src/main/resources/production/* $buildPath/bossserver/WEB-INF/classes/");
        #system("cp -f $SPath{SVN}/trackserver/src/main/resources/production/* $buildPath/trackserver/WEB-INF/classes/");
        system("cp -f $SPath{SVN}/pokerserver/src/main/resources/production/* $buildPath/pokerserver/conf/");
    }elsif($section=~/mkl/i){
        system("cp -f $SPath{SVN}/gameserver/src/main/resources/production/* $buildPath/gameserver/WEB-INF/classes/");
        system("cp -f $SPath{SVN}/taskserver/src/main/resources/production/* $buildPath/taskserver/conf/");
        system("cp -f $SPath{SVN}/logserver/src/main/resources/production/* $buildPath/logserver/WEB-INF/classes/");  
        system("cp -f $SPath{SVN}/bossserver/src/main/resources/production/* $buildPath/bossserver/WEB-INF/classes/");      
    }elsif($section=~/goc_guest/i){
        system("cp -f $SPath{SVN}/gameserver/src/main/resources/mobile_guest_prod/* $buildPath/gameserver/WEB-INF/classes/");
        system("cp -f $SPath{SVN}/taskserver/src/main/resources/mobile_guest_prod/* $buildPath/taskserver/conf/");
        system("cp -f $SPath{SVN}/logserver/src/main/resources/mobile_guest_prod/* $buildPath/logserver/WEB-INF/classes/");  
        system("cp -f $SPath{SVN}/bossserver/src/main/resources/mobile_guest_prod/* $buildPath/bossserver/WEB-INF/classes/");
    }elsif($section=~/gli/i){
        system("cp -f $SPath{SVN}/gameserver/src/main/resources/onlineGame/* $buildPath/gameserver/WEB-INF/classes/");
        system("cp -f $SPath{SVN}/logserver/src/main/resources/onlineGame/* $buildPath/logserver/WEB-INF/classes/");  
        system("cp -f $SPath{SVN}/bossserver/src/main/resources/onlineGame/* $buildPath/bossserver/WEB-INF/classes/");    
    }
}

sub modifyGlobalConf($;$;$){
    #array[0]: Internal IP array[1]: External IP;
    my @gameServerIP = split(/,/,$gameServerIP);
    my @pokerSrvIP = split(/,/,$pokerSrvIP);
    my @bossServerIP = split(/,/,$bossServerIP);
    my @logServerIP = split(/,/,$logServerIP);
    my @taskServerIP = split(/,/,$taskServerIP);

    #$module: which moudle do you want to change, $fileName: which config file do you want to change;
    #$conf:0 modify servers' configuration $conf:1 modify log4j configuration. 
    my $logPath="";
    my ($module,$conf,$fileName) = @_;
    if ($module eq "game"){
        chdir("$buildPath/gameserver/WEB-INF/classes");
        $logPath = "/srv/apache-tomcat/logs/gameserver.log";
    }elsif($module eq "poker"){
        chdir("$buildPath/pokerserver/conf");
        $logPath = "/srv/taskserver/logs/pokerserver.log";
    }elsif($module eq "task"){
        chdir("$buildPath/taskserver/conf");
        $logPath = "/srv/taskserver/logs/taskserver.log";
    }elsif($module eq "log"){
        chdir("$buildPath/logserver/WEB-INF/classes");
        $logPath = "/srv/logserver/logs/logserver.log";
    }elsif($module eq "boss"){
        chdir("$buildPath/bossserver/WEB-INF/classes");
        $logPath = "/srv/apache-tomcat/logs/bossserver.log";
    }elsif($module eq "track"){
        chdir("$buildPath/trackserver/WEB-INF/classes");
        $logPath = "/srv/apache-tomcat/logs/trackserver.log";
    }
    if ($conf == 0){         #$conf:0 modify servers' configuration.
        #Change configuration for redis
        print "Modify $module server configuration in $fileName\n";
        @redis=split(/:/,$redisGlobal);      
        system("perl -pi -e 's#\\\${jedis.global.host}#$redis[0]#g' ./$fileName") if (-e "./$fileName");
        system("perl -pi -e 's#\\\${jedis.global.port}#$redis[1]#g' ./$fileName") if (-e "./$fileName");
        @redis=split(/:/,$redisPlayer);
        system("perl -pi -e 's#\\\${jedis.player.host}#$redis[0]#g' ./$fileName") if (-e "./$fileName");
        system("perl -pi -e 's#\\\${jedis.player.port}#$redis[1]#g' ./$fileName") if (-e "./$fileName");
        @redis=split(/:/,$redisQueue);
        system("perl -pi -e 's#\\\${jedis.queue.host}#$redis[0]#g' ./$fileName") if (-e "./$fileName");
        system("perl -pi -e 's#\\\${jedis.queue.port}#$redis[1]#g' ./$fileName") if (-e "./$fileName");
        @redis=split(/:/,$redisSession);
        system("perl -pi -e 's#\\\${jedis.session.host}#$redis[0]#g' ./$fileName") if (-e "./$fileName");
        system("perl -pi -e 's#\\\${jedis.session.port}#$redis[1]#g' ./$fileName") if (-e "./$fileName");
        
        system("perl -pi -e 's#\\\${redis.dump.time}#$dumpTime#g' ./$fileName") if (-e "./$fileName");
        system("perl -pi -e 's#\\\${redis.cold.time}#$coldTime#g' ./$fileName") if (-e "./$fileName");
        system("perl -pi -e 's#\\\${player.data.dump.trigger}#$dumpTrigger#g' ./$fileName") if (-e "./$fileName");
        
        #Change host for task server
        system("perl -pi -e 's#\\\${progressive.rpchost}#$taskServerIP[0]#g' ./$fileName") if (-e "./$fileName");
        
        #Change hosts for Cobar and MYSQL 
        system("perl -pi -e 's#\\\${datasource.cobar}#$cobarIP#g' ./$fileName") if (-e "./$fileName");
        system("perl -pi -e 's#\\\${datasource.mysql}#$DBIP#g' ./$fileName") if (-e "./$fileName");
        
        #Set encryption in game server
        system("perl -pi -e 's#\\\${compressAmf}#$compressAmf#' ./$fileName") if (-e "./$fileName");
        
        #Set hadoop configuration
        system("perl -pi -e 's#\\\${zookeeperQuorum}#$zookeeperQuorum#g' ./$fileName") if (-e "./$fileName");
        system("perl -pi -e 's#\\\${hiveIP}#$hiveIP#g' ./$fileName") if (-e "./$fileName");
        system("perl -pi -e 's#segment.writeKey\\s*=.*#segment.writeKey=$writeKey#g' ./$fileName") if (-e "./$fileName");
        
    }elsif($conf == 1){                  #$conf:1 modify log4j configuration.
        print "Modify $module log configuration\n";
        system("perl -pi -e 's#log4j.rootLogger\\s*=\\s*(.*)logfile#log4j.rootLogger=WARN,stdout,logfile#' ./$fileName") if (-e "./$fileName");
        system("perl -pi -e 's#log4j.appender.logfile.File\\s*=\\s*(.*)log#log4j.appender.logfile.File=$logPath#' ./$fileName") if (-e "./$fileName");
    }
}

sub modifyClientConf(){
    chdir("$buildPath/client");
    if (-e "shell.html"){
        print "Modify configuration in shell.xml...\n";
        system("perl -pi -e 's#test_goc#prod_goc#g' ./shell.html");
    }
}

sub createPkg(){
    #Delete log files before create production packages.
    system("rm -fR $buildPath/pokerserver/logs");
    system("rm -fR $buildPath/logserver/logs");
    system("rm -fR $buildPath/taskserver/logs");
    
    chdir("$buildPath");
    print "Create tar package for taskserver, logserver and client...\n";
    foreach(@pkgs){
        if($_=~/gameSrv/i){
            system("tar -zcf gameserver.tar.gz ./gameserver");   
        }
        if($_=~/client/i){
            system("tar -zcf client.tar.gz ./client");    
        }
        if($_=~/pokerSrv/i){
            system("tar -zcf pokerserver.tar.gz ./pokerserver");
        }
        if($_=~/bossSrv/i){
            system("tar -zcf bossserver.tar.gz ./bossserver");    
        }
        if($_=~/logSrv/i){
            system("tar -zcf logserver.tar.gz ./logserver");    
        }
        if($_=~/taskSrv/i){
            system("tar -zcf taskserver.tar.gz ./taskserver"); 
        }
        if($_=~/trackSrv/i){
            system("tar -zcf trackserver.tar.gz ./trackserver");   
        }
        if($_=~/gameSite/i){
            system("tar -zcf gamesite.tar.gz ./gamessite");    
        }
    }

    print "Backup packages to $SPath{home}/bak/$section folder...\n";
    delExpireBak(30); #delete bak file expire 30 days.
    my $time=`date +%Y-%m-%d`;
    chomp($time);
    my @tar = glob "$buildPath/*.tar.gz";
    #Create backup folder if the folder doesn't exist.
    system("mkdir -p $SPath{home}/bak/$section") unless(-e "$SPath{home}/bak/$section");
    foreach(@tar){
        $_ = ~/$buildPath\/(.*)\.tar\.gz/;
        my $file=$1;
        #print "tar = $_\n pkg = $file\n";
        if ($isTesting=~/true/i){
            print "pkg = $file\n";
            system("cp -f $buildPath/$file.tar.gz $SPath{home}/bak/$section/$file-test-$time.tar.gz");
        }elsif($isTesting=~/false/i){
            print "pkg = $file\n";
            system("cp -f $buildPath/$file.tar.gz $SPath{home}/bak/$section/$file-$time.tar.gz");    
        }
    }
}

sub delExpireBak($){
    my $expire = shift; #Unit:day
    $expire = $expire*24*60*60;
    my @files = glob("$SPath{home}/bak/$section/*");
    foreach(@files){
        if(time()-(stat($_))[9]>$expire){
            print "Delete file $_\n";
            unlink($_);
        }
    }
}
#our %isUpload=(
#    "gameSrv"=>"false",
#    "client"=>"false",
#    "bossSrv"=>"false",
#    "logSrv"=>"false",
#    "taskSrv"=>"false",
#    "pokerSrv"=>"false",
#    "trackSrv"=>"false",
#    "gameSite"=>"false",
#);
sub isUpload(){
    my $id=2;
    print "Please choose upload packages ID or all\n";
    print "1. all\n";
    foreach(@pkgs){
        print "$id. $_\n";
        $id++;
    }
    print "$id. None\n";
    chomp($result = <STDIN>);
    if($section=~/^goc\d?$/i){
        if($result=~/1|2/){
            $isUpload{gameSrv}="true";
        }
        if($result=~/1|3/){
            $isUpload{client}="true";
        }
        if($result=~/1|4/){
            $isUpload{bossSrv}="true";
        }
        if($result=~/1|5/){
            $isUpload{logSrv}="true";
        }
        if($result=~/1|6/){
            $isUpload{taskSrv}="true";
        }
        if($result=~/1|7/){
            $isUpload{pokerSrv}="true";
        }
        if($result=~/1|8/){
            $isUpload{trackSrv}="true";
        }
    }
    if($section=~/goc_guest|mkl/i){
        if($result=~/1|2/){
            $isUpload{gameSrv}="true";
        }
        if($result=~/1|3/){
            $isUpload{bossSrv}="true";
        }
        if($result=~/1|4/){
            $isUpload{logSrv}="true";
        }
        if($result=~/1|5/){
            $isUpload{taskSrv}="true";
        }
    }
   if($section=~/gli/i){
        if($result=~/1|2/){
            $isUpload{gameSrv}="true";
        }
        if($result=~/1|3/){
            $isUpload{bossSrv}="true";
        }
        if($result=~/1|4/){
            $isUpload{logSrv}="true";
        }
        if($result=~/1|5/){
            $isUpload{gameSite}="true";
        }
    }
}
#our %isUpload=(
#    "gameSrv"=>"false",
#    "client"=>"false",
#    "bossSrv"=>"false",
#    "logSrv"=>"false",
#    "taskSrv"=>"false",
#    "pokerSrv"=>"false",
#    "trackSrv"=>"false",
#    "gameSite"=>"false",
#);
sub uploadPkg(){
    # select packages you want to upload.
    isUpload();
    chdir("$buildPath");
    #array[0]: Internal IP array[1]: External IP;
    my @gameServerIP = split(/,/,$gameServerIP);
    my @pokerSrvIP = split(/,/,$pokerSrvIP);
    my @bossServerIP = split(/,/,$bossServerIP);
    my @logServerIP = split(/,/,$logServerIP);
    my @taskServerIP = split(/,/,$taskServerIP);
    
    if ($isUpload{gameSrv}=~/true/i){
        print "Upload gameSrv...\n";
        system("pscp -pw $DPath{pwd} -P $DPath{port} ./gameserver.tar.gz $DPath{user}\@$gameServerIP[1]:/$DPath{client}");     
    }
    if ($isUpload{client}=~/true/i){
        print "Upload client...\n";
        system("pscp -pw $DPath{pwd} -P $DPath{port} ./client.tar.gz $DPath{user}\@$gameServerIP[1]:/$DPath{client}");
    }
    if($isUpload{bossSrv}=~/true/i){
        print "Upload bossSrv...\n";
        system("pscp -pw $DPath{pwd} -P $DPath{port} ./bossserver.tar.gz $DPath{user}\@$bossServerIP[1]:/$DPath{server}")
    }
    if($isUpload{logSrv}=~/true/i){
        print "Upload logSrv...\n";
        system("pscp -pw $DPath{pwd} -P $DPath{port} ./logserver.tar.gz $DPath{user}\@$bossServerIP[1]:/$DPath{server}")
    }
    if ($isUpload{taskSrv}=~/true/i){
        print "Upload taskSrv...\n";
        system("pscp -pw $DPath{pwd} -P $DPath{port} ./taskserver.tar.gz $DPath{user}\@$taskServerIP[1]:/$DPath{server}")     
    }
    if ($isUpload{pokerSrv}=~/true/i){
        print "Upload pokerSrv...\n";
        system("pscp -pw $DPath{pwd} -P $DPath{port} ./pokerserver.tar.gz $DPath{user}\@$pokerSrvIP[1]:/$DPath{client}")
    }
    if($isUpload{trackSrv}=~/true/i){
        print "Upload trackSrv...\n";
        system("pscp -pw $DPath{pwd} -P $DPath{port} ./trackserver.tar.gz $DPath{user}\@$bossServerIP[1]:/$DPath{server}")
    }
    if($isUpload{gameSite}=~/true/i){
        print "Upload gameSite...\n";
        system("pscp -pw $DPath{pwd} -P $DPath{port} ./gamesite.tar.gz $DPath{user}\@$gameServerIP[1]:/$DPath{server}");
    }
    
    print "Backup packages to S3 on AWS\n";
    system("s3cmd --delete-removed sync $SPath{home}/bak/$section/ s3://aspectgaming-databackup/pkg/$section/");
    
    #if ($platform=~/fb/i){
    #    system("s3cmd --delete-removed sync /home/qa/ProductionPackage/bak/ s3://aspectgaming-databackup/pkg/FB/");
    #}elsif($platform=~/ml/i){
    #    system("s3cmd --delete-removed sync /home/qa/ProductionPackage/bak/ s3://aspectgaming-databackup/pkg/ML/");
    #}elsif($platform=~/guest/i){
    #    system("s3cmd --delete-removed sync /home/qa/ProductionPackage/bak/ s3://aspectgaming-databackup/pkg/GOC-Mobile/");
    #}
}

sub backupDB(){
    #deployment IP:10.144.85.70;
    print "Starting backup onlinegame DB...\n";
    system("plink -ssh -pw aspect aspect\@10.144.85.70 '/home/aspect/script/GameDbBackup.py production onlinegame'");
    
    print "Starting backup global DB...\n";
    system("plink -ssh -pw aspect aspect\@10.144.85.70 '/home/aspect/script/GameDbBackup.py production global'");
}

######################## Main Program #################################
readConf();

print "Do you want to get packages from servers?(y/n)";
chomp($result = <STDIN>);
$result = lc($result);
if ($result eq "y"){
    my $startTime=time();
    getFiles();
    my $totalTime=time()-$startTime;
    print "It takes $totalTime secs to get packages\n";
    
}

print "Do you want to modify configuration and build tar packages?(y/n)";
chomp($result = <STDIN>);
$result = lc($result);
if ($result eq "y"){
    modifyGlobalConf("game","0","game-conf.properties");
    modifyGlobalConf("task","0","task-conf.properties");
    modifyGlobalConf("poker","0","poker-conf.properties");
    modifyGlobalConf("log","0","log-conf.properties");
    modifyGlobalConf("boss","0","boss-conf.properties");
    modifyGlobalConf("track","0","track-conf.properties");
    modifyClientConf();
    createPkg();
}

print "Do you want to upload packages to servers?(y/n)";
chomp($result = <STDIN>);
$result = lc($result);
if ($result eq "y"){
    uploadPkg();
}