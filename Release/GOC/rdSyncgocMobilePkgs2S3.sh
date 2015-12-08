#! /bin/bash
# production flash cpoy and synchronization script

##
s3url=s3://aspect-gaming-flash
s3bakurl=s3://aspectgaming-databackup/pkg/goc_mobile_update
testing=$s3url/test_gocmobile
production=$s3url/prod_gocmobile
log_dir=/home/qa/ProductionPackage/log
log=`basename $0|awk -F '.' '{print $1".log"}'`
command=`which s3cmd`

error=ERROR
info=INFO

##

## main function
datetime(){
     date=`date  '+%Y-%m-%d %H:%M:%S'`
     echo $date
}

s3cmd_sync() {    
    echo "--Begin sync $testing/$version to $production"
    echo "[`datetime`] $info:starit sync $testing/$version to $production" >>$log_dir/$log
    s3cmd sync -P --add-header=Cache-Control:no-cache --recursive $testing/$version $production/ |tee -a $log_dir/$log
    if [ $? != 0 ]
    then
        echo "[`datetime`] $error:sync $testing/$version to $production failure"  >>$log_dir/$log
        echo "--sync $testing/$version to $production failure"
        exit 2
    else
        echo "[`datetime`] $info:sync $testing/$version to $production success"  >>$log_dir/$log
        echo "--sync $testing/$version to $production success"
    fi    
    
    
    echo "--Begin sync $testing/$version to $s3bakurl/$version"
    echo "[`datetime`] $info:starit sync $testing/$version to $s3bakurl" >>$log_dir/$log
    s3cmd sync -P --add-header=Cache-Control:no-cache --recursive $testing/$version $s3bakurl/ |tee -a $log_dir/$log
    if [ $? != 0 ]
    then
        echo "[`datetime`] $error:sync $testing/$version to $s3bakurl failure"  >>$log_dir/$log
        echo "--sync $testing/$version to $s3bakurl failure"
        exit 2
    else
        echo "[`datetime`] $info:sync $testing/$version to $s3bakurl success"  >>$log_dir/$log
        echo "--sync $testing/$version to $s3bakurl success"
    fi    
}


#######################################Main Program####################################
rm -rf $log_dir/$log

if [ "$1" = "" ];then
    echo "ERROR:Please input release version"
    exit 1
fi

if [ "$1" != "$2" ] ;then
    echo "ERROR:Version doesn't match"
    exit 1
fi



version=$1



s3cmd_sync
