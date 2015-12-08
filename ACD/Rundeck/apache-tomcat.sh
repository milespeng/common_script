#! /bin/bash
# Apache-Tomcat status,start,stop and restart script

####################################################
#   Author: Jack.zhang
#   Modified by Bessie.Yang
#   Update by Wayne on Aug 3 2015
#   Change Logs:
#   Aug 3 2015
#       Add the status function
#       Make sure that the tomcat process start only one
#   Sep 16 2015
#	update the stop funtion and stdout
#################################################### 

EXECUTABLE=/bin/catalina.sh
export TOMCAT_HOME=/srv/$1
echo "Tomcat home is: $TOMCAT_HOME"   

if [ -z "$TOMCAT_HOME" ]
then
    echo  "Error:You have no configuration TOMCAT_HOME environment variable"
    exit 1
fi
RETVAL=0

#CHECK LOCK
LOCKFILE=/tmp/tomcat.lock
if [ -f "$LOCKFILE" ]
	then
		pid=`cat $LOCKFILE`
		ps -a | grep -q "$pid"
		[ $? = 0 ] && echo "Warn: Script is running......" && exit 1
	else
		echo $$ >"$LOCKFILE"
fi

start() {
    # check if the tomcat is running
    TOMCAT_PID=`ps -ef | grep "$1" | grep -Ev "grep|\.sh" | awk '{print $2}'`
    if [ -n "$TOMCAT_PID"  ]; then
         echo "Warn: tomcat is still running!"
         exit 1
    fi

    # resolve links - $0 may be a softlink
    PRG="$0"
    while [ -h "$PRG" ] ; do
        ls=`ls -ld "$PRG"`
        link=`expr "$ls" : '.*-> \(.*\)$'`
        if expr "$link" : '/.*' > /dev/null; then
          PRG="$link"
        else
          PRG=`dirname "$PRG"`/"$link"
        fi
    done
 
    eval
    if [ ! -f "$TOMCAT_HOME$EXECUTABLE" ]; then
       echo "Error: Cannot find TOMCAT_HOME $EXECUTABLE"
       echo "The file is absent or does not have execute permission"
       echo "This file is needed to run this program"
       exit 1
    fi 
    echo -n "Tomcat Starting..."
    echo 
    $TOMCAT_HOME$EXECUTABLE start
}

stop() {
    # check if the tomcat is running
    TOMCAT_PID=`ps -ef | grep "$1" | grep -Ev "grep|\.sh" | awk '{print $2}'`
    if [ -z "$TOMCAT_PID"  ]; then
         echo "Warn: tomcat is not running!"
	 return
    fi

    # resolve links - $0 may be a softlink
    PRG="$0"
    while [ -h "$PRG" ] ; do
        ls=`ls -ld "$PRG"`
        link=`expr "$ls" : '.*-> \(.*\)$'`
        if expr "$link" : '/.*' > /dev/null; then
          PRG="$link"
        else
          PRG=`dirname "$PRG"`/"$link"
        fi
    done

    eval
    if [ ! -f "$TOMCAT_HOME$EXECUTABLE" ]; then
       echo "Error: Cannot find TOMCAT_HOME $EXECUTABLE"
       echo "The file is absent or does not have execute permission"
       echo "This file is needed to run this program"
       exit 1
    fi
    echo -n "Tomcat Stopping..."
    echo 
    $TOMCAT_HOME$EXECUTABLE stop
    sleep 10

    TOMCAT_PID=`ps -ef | grep $1 | grep -Ev "grep|\.sh" | awk '{print $2}'`
    if [ -n "$TOMCAT_PID" ]
    then
        echo "Warn: apache-tomcat Can't normally closed"
        echo "Will Execute the function kill"
        kill   $TOMCAT_PID
        sleep 2
	TOMCAT_PID=`ps -ef | grep $1 | grep -Ev "grep|\.sh" | awk '{print $2}'`
    if [ -n "$TOMCAT_PID" ]
        then
            kill -9 $TOMCAT_PID
        else
            echo "Execute kill success"
        fi
        
    fi
}

restart() {
    echo -n "Tomcat restart..."
    echo 
    stop $1
    echo '---------------------------------------------'
    start $1
}

status() {
    TOMCAT_PID=`ps -ef | grep $1 | grep -Ev "grep|\.sh" | awk '{print $2}'`
    if [ -n "$TOMCAT_PID"  ]
    then
         echo "tomcat is running!"
         return 0
    else
         echo "tomcat is not running!"
         return 1
    fi
}

case "$2" in
 start)
     start $1;;
 stop)
     stop $1;;
 restart)
     restart $1;;
 status)
     status $1;;
 *) 
     echo "Usage: $0 {relative/path/to/apache-tomcat} {start|stop|restart}"
     exit 1
esac

rm -rf $LOCKFILE
