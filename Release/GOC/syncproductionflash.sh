#! /bin/bash
# production flash cpoy and synchronization script


##

config_dir=/home/qa/deployment/build/goc/onlineGameFlash.war/lobby
storage_file=/home/qa/ProductionPackage/build/onlineGameFlash.war/lobby
config=configuration.xml

##
s3url=s3://aspect-gaming-flash
testing=$s3url/testing
production=$s3url/production
log_dir=/home/qa/ProductionPackage/log
log=`basename $0|awk -F '.' '{print $1".log"}'`
command=`which s3cmd`

error=ERROR
info=INFO

##
gameSrv=www.grandorientcasino.com
pokerServer=54.215.250.166
bossServer=54.215.250.163
tulpes=(en_US es_ES th_TH zh_TW)
test888=test888.grandorientcasino.com
testip=54.215.252.134
gaID=GOC_FB
#gaID=GOC_QA





## main function
datetime(){
     date=`date  '+%Y-%m-%d %H:%M:%S'`
     echo $date
}




s3cmd_ls() {
    cdn_version=`s3cmd ls $s3url/production/|grep -o '/production/[0-9]\{2,5\}'|sed "s/\/production\///g"`
    find_version=`echo $cdn_version|grep -o $version`
    ls_cp(){
        if [ "$version" = "$find_version" ];then
           echo -n "You input the $version version of the s3 already exists,Do you need to cover?<y/n>:"
           read value
           if [ "$value" = "y" ];then
               echo "" >/dev/null
           elif [ "$value" = "n" ];then
               exit 1
           else
               echo "The value you input does not exist."
               exit 1
           fi
        else
            echo "" >/dev/null
        fi
    }
    ls_sync(){
        if [ "$version" = "$find_version" ];then
            echo -n "Your input $version version of the s3 already exists,Do you need to synchronize?<y/n>:"
            read value
            if [ "$value" = "y" ];then
                 echo "" >/dev/null
            elif [ "$value" = "n" ];then
                 exit 1
            else
                 echo "The value you input does not exist."
            fi
        else
            echo "" >/dev/null
        fi
    }
}
     





s3cmd_cp() {

    cp_lobby(){
        echo "--Begin cp $testing/lobby to $production/$version/lobby"
        echo "[`datetime`] $info:start cp $testing/lobby to $production/$version/lobby" >>$log_dir/$log
        $command cp -P --recursive --force --add-header=Cache-Control:no-cache $testing/lobby $production/$version/ >>$log_dir/s3cmd.log
        if [ $? != 0 ]
        then
            echo "[`datetime`] $error:cp $testing/lobby to $production/$version/lobby failure" >>$log_dir/$log
            echo "--cp $testing/lobby to $production/$version/lobby failure"
            exit 2
        else
            echo "[`datetime`] $info:cp $testing/lobby to $production/$version/lobby success"  >>$log_dir/$log
            echo "--cp $testing/lobby to $production/$version/lobby success"
        fi
    }
              
    cp_casino(){
        echo "--Begin cp $testing/casino to $production/$version/casino"
        echo "[`datetime`] $info:start cp $testing/casino to $production/$version/casino" >>$log_dir/$log
        $command cp -P --recursive --force --add-header=Cache-Control:no-cache $testing/casino $production/$version/ >>$log_dir/s3cmd.log
        if [ $? != 0 ]
        then
            echo "[`datetime`] $error:cp $testing/casino to $production/$version/casino failure" >>$log_dir/$log
            echo "--cp $testing/casino to $production/$version/casino failure"
            exit 2
        else
            echo "[`datetime`] $info:cp $testing/casino to $production/$version/casino success" >>$log_dir/$log
            echo "--cp $testing/casino to $production/$version/casino success"
        fi
    }

}


s3cmd_sync() {

    sync_lobby() {
        echo "--Begin sync $testing/lobby to $production/$version/lobby"
        echo "[`datetime`] $info:starit sync $testing/lobby to $production/$version/lobby" >>$log_dir/$log
        s3cmd sync -P --add-header=Cache-Control:no-cache --recursive $testing/lobby/ $production/$version/lobby/ |tee -a $log_dir/s3cmd.log
        if [ $? != 0 ]
        then
            echo "[`datetime`] $error:sync $testing/lobby to $production/$version/lobby failure"  >>$log_dir/$log
            echo "--sync $testing/lobby to $production/$version/lobby failure"
            exit 2
        else
            echo "[`datetime`] $info:sync $testing/lobby to $production/$version/lobby success"  >>$log_dir/$log
            echo "--sync $testing/lobby to $production/$version/lobby success"
        fi
    }
    sync_casino() {
        echo "--Begin sync $testing/casino to $production/$version/casino"
        echo "[`datetime`] $info:start sync $testing/casino to $production/$version/casino" >>$log_dir/$log
        s3cmd sync -P --add-header=Cache-Control:no-cache --recursive $testing/casino/ $production/$version/casino/ |tee -a $log_dir/s3cmd.log
        if [ $? != 0 ]
        then
            echo "[`datetime`] $error:sync $testing/lobby to $production/$version/casino failure"  >>$log_dir/$log
            echo "--sync $testing/lobby to $production/$version/casino failure"
            exit 2
        else
            echo "[`datetime`] $info:sync $testing/lobby to $production/$version/casino success"  >>$log_dir/$log
            echo "--sync $testing/lobby to $production/$version/casino success"
        fi
    }
}


prod_config() {

    if [ ! -d $config_dir ]
    then
        echo "[`datetime`] $error:$config_dir Directory does not exist."
        exit 2
    fi

    for file in "${tulpes[@]}" 
    do
        if [ ! -d $storage_file/$file/xml ]
        then
            mkdir -p $storage_file/$file/xml
        fi
        cp $config_dir/$file/xml/$config $storage_file/$file/xml/
        sed -i "s/testing/production\/$version/g" $storage_file/$file/xml/$config 
        sed -i "s/$test888/$gameSrv/g" $storage_file/$file/xml/$config
        sed -i "s/$testip:8124/$pokerServer:8124/g" $storage_file/$file/xml/$config 
        sed -i "s/http:\/\/.*:8080/http:\/\/$bossServer:8080/g" $storage_file/$file/xml/$config 
        #sed -i  "/gameAnalytics gaID/s/\"..*\"/\"$gaID\" gaVersion=\"$version\"/g" $storage_file/$file/xml/$config
        sed -i "/gameAnalytics/s/gaID=..*gaVersion/gaID=\"$gaID\" gaVersion/g" $storage_file/$file/xml/$config
        #split1=`echo $version|cut -b 1`
        #split2=`echo $version|cut -b 2`
        #split3=`echo $version|cut -b 3`
        #split="$split1.$split2.$split3"
        sed -i "/gameAnalytics/s/gaVersion=..*\/>/gaVersion=\"$version\" \/>/g"  $storage_file/$file/xml/$config

        s3cmd put -P --add-header=Cache-Control:no-cache $storage_file/$file/xml/$config  $production/$version/lobby/$file/xml/ |tee -a $log_dir/s3cmd.log
        if [ $? != 0 ]
        then
            echo "[`datetime`] $error:put $production/$version/lobby/$file/xml failure"
            echo "[`datetime`] $error:put $production/$version/lobby/$file/xml failure" >>$log_dir/$log
            exit 2
        else
            echo "[`datetime`] $info:put $production/$version/lobby/$file/xml success"
            echo "[`datetime`] $info:put $production/$version/lobby/$file/xml success"  >>$log_dir/$log
        fi
    done

}              


#######################################Main Program####################################
rm -rf $log_dir/s3cmd.log
if [ "$1" = "" ];then
    echo "`basename $0` Usage:{cp|sync|all}"    
    exit 1
fi

if [ "$2" = "" ];then
    echo "`basename $0` $1 Usage:{lobby|casino|all}"
    exit 1
fi

## vesrion
echo -n "Please input release version: "
read version
length=`expr length $version`
#if [ "$length" -ge "4" ]
#then
#    echo  "Error: Does not support version $length number"
#    exit 1
#fi


if [ "$1" = "cp" ] ;then
    case $2 in
             lobby)
                 s3cmd_ls
                     ls_cp
                 s3cmd_cp
                     cp_lobby
                 ;;

             casino)
                 s3cmd_ls
                     ls_cp
                 s3cmd_cp
                     cp_casino
                 exit 1
                 ;;
                          
             all)
                 s3cmd_ls
                     ls_cp
                 s3cmd_cp
                     cp_lobby
                 s3cmd_cp
                     cp_casino
                 ;;
             *)
                 echo "`basename $0` $1 Usage:{lobby|casino|all}"

    esac

elif [ "$1" = "sync" ] ;then
    case $2 in
             lobby)
                  
                 s3cmd_ls
                     ls_sync
                 s3cmd_sync
                     sync_lobby
                 ;;

             casino)
                 s3cmd_ls
                     ls_sync
                 s3cmd_sync
                     sync_casino
                 exit 1
                 ;;

             all)
                 s3cmd_ls
                     ls_sync
                 s3cmd_sync
                     sync_lobby
                     sync_casino
                 ;;
             *)
                 echo "`basename $0` $1 Usage:{lobby|casino|all}"
    esac

elif [ "$1" = "all" ] ;then
    s3cmd_ls
        ls_cp
    s3cmd_cp
        cp_lobby
        cp_casino
    s3cmd_ls
        ls_sync
    s3cmd_sync
        sync_lobby
        sync_casino

else
    echo "`basename $0` Usage:{cp|sync|all}"
    exit 1
fi

prod_config
