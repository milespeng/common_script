#!/usr/bin/perl

use strict;
use Config::Tiny;

our ($daemon_name,$action,$conf,$DAEMON_PATH,$JAVA_OPTS,$DAEMON_CLASSPATH,$Dhome,$project_properties,$DAEMON_PID,$LOCKFILE,@section,$section);
our $success = "\033[32;1;5mSuccess\033[m";
our $fail = "\033[31;1;5mFail\033[m";
our $Error = "\033[31;1;5mError\033[m";
our $JAVA_HOME = $ENV{JAVA_HOME};

sub readConf(){
	my $section = shift;
	chdir("/home/qa/deployment/script");
        $conf = Config::Tiny->read("/home/qa/deployment/script/conf/daemon.ini") || die "daemon.ini, ERROR:$!\n";
	our $JAVA_OPTS = $conf->{$section}->{JAVA_OPTS};
	our $DAEMON_PATH = $conf->{$section}->{DAEMON_PATH};
	our $DAEMON_CLASSPATH = $conf->{$section}->{DAEMON_CLASSPATH};
	our $Dhome = $conf->{$section}->{Dhome};
	our $project_properties = $conf->{$section}->{project_properties};
}

sub check_env(){
        my $noJavaHome = "false";
        if(!("$JAVA_HOME/bin/java" =~ /java/)){
                $noJavaHome = "true";
        }
        if ($noJavaHome =~ /true/){
                print "\n";
                print "$Error: JAVA_HOME environment variable is not set.";
                print "\n";
                exit 1;
        }
#        if(!(-d our $DAEMON_PATH)){
#                print "$DAEMON_PATH directory does not exist\n";
#        }
}

sub start(){
	my $section = shift;
	my $DAEMON_PID = `ps -ef | grep $DAEMON_PATH | grep -v grep | grep -v daemon | awk '{print \$2}'`;
        chomp($DAEMON_PID);

        if ( $DAEMON_PID ){
                print "$Error: $section have started!\n";
		return 1;
#		exit 1;
        }

        chdir("$DAEMON_PATH/lib");
        opendir PH,"./";
        foreach (readdir PH){
                chomp $_;
                if ( $_ =~ /jar/ ){
                        $DAEMON_CLASSPATH="$DAEMON_CLASSPATH:$DAEMON_PATH/lib/$_";
                }
        }
        closedir (PH);
        my $java = "$JAVA_HOME/bin/java";
        print "$section Starting...\n";
        my $cmd="$java $Dhome=$DAEMON_PATH -classpath $DAEMON_CLASSPATH $JAVA_OPTS $project_properties";
#	print "$cmd\n";

	system("$cmd >> $DAEMON_PATH/logs/console.log 2>&1 > /dev/null &");
        sleep 5;
        $DAEMON_PID = `ps -ef | grep $DAEMON_PATH | grep -v grep | grep -v daemon | awk '{print \$2}'`;
        chomp($DAEMON_PID);
        if ( $DAEMON_PID ){
                print "$success: $section have started!\n";
        }else{
		print "$Error: $section started fail\n";
		return 1;
#		exit 1;
        }
}

sub stop(){
        #check if the daemon is running
	my $section = shift;
        my $DAEMON_PID = `ps -ef | grep $DAEMON_PATH | grep -v grep | grep -v daemon | awk '{print \$2}'`;
        chomp($DAEMON_PID);
        if ( ! $DAEMON_PID ){
                print "Warn: $section have stopped!\n";
                return 0;
        }else{
                print "$section Stoping...\n";
                system("kill -9 $DAEMON_PID");
        }
        sleep 5;
        $DAEMON_PID = `ps -ef | grep $DAEMON_PATH | grep -v grep | grep -v daemon | awk '{print \$2}'`;
        chomp($DAEMON_PID);
        if ( ! $DAEMON_PID ){
                print "$success: $section have stopped!\n";
        }else{
                print "$Error: $section is still running!\n";
		        return 1;
#		        exit 1;
        }
}

sub restart(){
	my $section = shift;
        &stop($section);
        sleep 5;
        &start($section);
}

sub status($){
	my $section = shift;
	my $DAEMON_PID = `ps -ef | grep $DAEMON_PATH | grep -v grep | grep -v daemon | awk '{print \$2}'`;
        chomp($DAEMON_PID);
        if ( ! $DAEMON_PID  ){
             print " * $section stopped!\n";
             return 0;
        }else{
             print " * $section start/running, process $DAEMON_PID\n";
             return 1;
        }
}

sub help(){
        print "############ Help ############\n";
        print "Usage: ./daemon.pl {relative/path/to/daemon} {start|stop|restart|status}\n";
        print "eg.: ./daemon.pl pokertask,pokergame {start|stop|restart|status}\n";
        print "     ./daemon.pl pokertask {start|stop|restart|status}\n";
        print "##############################\n";
}

################################### Main Program #################################
$daemon_name = $ARGV[0];
$action = $ARGV[1];
if (scalar(@ARGV) != 2){
        &help();
        exit 1;
}

our @section = split(/,/,$daemon_name);
foreach(@section){
	&readConf($_);
	&check_env();
	if($action eq "start"){
		&start($_);
	}elsif($action eq "stop"){
		&stop($_);
	}elsif($action eq "status"){
		&status($_);
	}elsif($action eq "restart"){
		&restart($_);
	}
}