#!/usr/bin/perl -w
#use strict;
use Log::Log4perl;
use Config::Tiny;
#use Posix;

our $projPath="/home/qa/Git/makeliving/client-android/";
our $buildPath="$projPath/mkl";
our $apkPath="$buildPath/bin";
our $originalApkName="MainActivity-release.apk";
our $releaseNotePath="/home/qa/deployment/script/mkl_android/releaseNote.txt";
our $scriptRunPath="/home/qa/deployment";

sub getTime
{
   #time()函数返回从1970年1月1日起累计秒数
    my $time = shift || time();

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);

    $sec  = ($sec<10)?"0$sec":$sec;#秒数[0,59]
    $min  = ($min<10)?"0$min":$min;#分数[0,59]
    $hour = ($hour<10)?"0$hour":$hour;#小时数[0,23]
    $mday = ($mday<10)?"0$mday":$mday;#这个月的第几天[1,31]
    $mon = $mon+1;
    $mon = ($mon<10)?"$mon":$mon;#月数[0,11],要将$mon加1之后，才能符合实际情况。
    #$mon  = ($mon<9)?"0".($mon+1):$mon;
    $year+=1900;#从1900年算起的年数

    #$wday从星期六算起，代表是在这周中的第几天[0-6]
    #$yday从一月一日算起，代表是在这年中的第几天[0,364]
    # $isdst只是一个flag
    my $weekday = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat')[$wday];
    return { 'second' => $sec,
             'minute' => $min,
             'hour'   => $hour,
             'day'    => $mday,
             'month'  => $mon,
             'year'   => $year,
             'weekNo' => $wday,
             'wday'   => $weekday,
             'yday'   => $yday,
             'date'   => "$year$mon$mday"
          };
}

sub logName(){
   my $today=`date  -d'0 day' +'%y%m%d' | tr -d '\r\n'`;
   my $logFileName="$scriptRunPath/log/mkl_android/mkl_android$today.log";
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

sub readConf($){
    my $section=shift;
    my $conf = Config::Tiny->read("$scriptRunPath/script/mkl_android/rdUpdateMKLAndroid.ini");
    if ($conf->{$section} eq ""){
        print "Section doesn't exist, please check out rdUpdateMKLAndroid.ini to find correct section!\n";
        exit(1);
    }
     $s3Dict=$conf->{$section}->{s3Dict};
     $webURLPrifx=$conf->{$section}->{webURLPrifx};
     $svn=$conf->{$section}->{svn};
     #$gameserverUrl=$conf->{$section}->{gameserverUrl};
}

sub sendLogMail(){
   system ("$scriptRunPath/script/UpdateEmail.py mkl_android mkl_android");
   $log->info("successfully send email");
}

sub isBuildFailed($){
   my $msg=shift;
   print "$msg\n";
   if($msg=~/BUILD FAILED/i){
      $log->info("Build failed, exit script!");
      exit(1);
   }
}


sub isPullFailed($){
   my $msg=shift;
   print "$msg\n";
   if($msg=~/error/i){
      $log->info("Pull code from git failed, exit script!");
      exit(1);
   }
}

sub switchBranch(){
   chdir("$projPath");
   $log->info("Your input branch name is: $branchName");   
   #switch to the branch
   our $switchResult = `git checkout $branchName`;
   isPullFailed("$switchResult");
   $log->info($switchResult);
}



sub updateProj(){
   chdir("$projPath");
   $log->info("-------------------Mail Starting--------------------");
   our $updateContent = `git reset --hard`;
   $updateContent = `git pull`;
   isPullFailed("$updateContent");
   $log->info($updateContent);
   $log->info("---------------------------------------------------");
   $log->info("-------------------Mail Ending--------------------");   
}

sub copyAssetAndReplaceConf{
   #file replaced:
   #1.client-android/mkl/src/com/parleylive/android/net/http/MklHttpClient.java
  if ($env =~ /mkl_prod/){
    print "copyAssetAndReplaceConf for production\n";
    chdir("$buildPath/src/com/parleylive/android/net/http/");
    system("/bin/cp $scriptRunPath/script/mkl_android/$env/MklHttpClient.java MklHttpClient.java");
    chdir("$buildPath/");
    system("/bin/cp $scriptRunPath/script/mkl_android/$env/AndroidManifest.xml AndroidManifest.xml");
  }
}

sub compileApk{
   chdir("$buildPath");

   our $compileRet = `ant clean release`;
 #  our $compileRet = `ant clean debug`;
   isBuildFailed("$compileRet");

   #rename apk with version and language
   if (-e "$apkPath/$originalApkName"){
       system("cp -rf $apkPath/$originalApkName $apkPath/\"$publicName\"");
    }else{
        $log->info("Release apk doesn't exist.Please confirm!");
        exist(1);
    }

   #regression
   if ($env =~ /mkl_prod/){
     chdir("$projPath");
     our $updateContent = `git reset --hard`;
     $updateContent = `git pull`;
   }
}

sub transferAndBackupApk{
   #s3cmd and svn backup
   if (-e "$apkPath/$publicName"){
       system("s3cmd put -P --recursive --force --add-header=Cache-Control:no-cache $apkPath/\"$publicName\" $s3Dict");
       #svn backup
			 chdir("$svn");
			 system("/usr/bin/svn update");
			 system("/bin/cp -rf $apkPath/\"$publicName\" $svn");
			 system("/usr/bin/svn add \"$publicName\"");
			 system("/usr/bin/svn commit -m \"Update MKL Android apk\" \"$publicName\"");
    }else{
        $log->info("Release apk doesn't exist and can't transfer it.Please confirm!");
        exist(1);
    }
}

sub writeReleaseNote{
    @release_Note=split /;/,$releaseNote;

	if (-e $releaseNotePath){
		system("rm -rf $releaseNotePath");
		#rmdir($releaseNotePath);
	}
	open OUT,">>$releaseNotePath";
	foreach $line(@release_Note){
			print OUT "$line\n";	
	}
}
####################################### main Program ########################################
our $env=$ARGV[0]; #testing or production
our $usage=$ARGV[1];
our $versionNO=$ARGV[2];
our $releaseNote=$ARGV[3];
our $language=$ARGV[4];
our $branchName=$ARGV[5] || "release";

my $date = &getTime();#获取当前系统时间的Hash
our $currentDate=$date->{year}.$date->{month}.$date->{day}."_".$date->{hour}.$date->{minute};
our $publicName = "PAL_".$currentDate."_".$versionNO;
if ($usage ne $env){
   $publicName .= "_".$usage;
}
$publicName .= ".apk";

initLog();
readConf($env);
#git switch branch
switchBranch();
#git pull
updateProj();
#copy asset
copyAssetAndReplaceConf();
#compile
compileApk();
#transfer apk to s3 if sucessful
transferAndBackupApk();
#write release note to file
writeReleaseNote();

#mail
sendLogMail();
system("$scriptRunPath/script/sendMail4Android/sendMail4Android.py PAL $versionNO $webURLPrifx$publicName $releaseNotePath $language");
