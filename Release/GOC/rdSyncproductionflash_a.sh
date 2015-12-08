#! /bin/bash
# production flash cpoy and synchronization script


##
git_dir_root=/home/qa/Git/goc_flash/goc_flash_webapp/
git_dir=/home/qa/Git/goc_flash/goc_flash_webapp/lobby
config_dir=/home/qa/deployment/build/goc_a/onlineGameFlash.war/lobby
storage_file=/home/qa/ProductionPackage/build/goc_a/onlineGameFlash.war/lobby
config=configuration.xml

##
s3url=s3://aspect-gaming-flash
testing=$s3url/test_goc_a
production=$s3url/prod_goc_a
backup=$s3url/test_goc_a_compatibility
log_dir=/home/qa/ProductionPackage/log
log=`basename $0|awk -F '.' '{print $1".log"}'`
command=`which s3cmd`

error=ERROR
info=INFO

##

gameSrv=test666.grandorientcasino.com
pokerServer=54.67.12.225
bossServer=52.8.215.75
tulpes=(en_US es_ES th_TH zh_TW)
test888=test999.grandorientcasino.com
testip=54.215.252.134
gaID=Prod_GOC_A
#gaID=GOC_QA
challengeId=880248862062203


## main function
datetime(){
     date=`date  '+%Y-%m-%d %H:%M:%S'`
     echo $date
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
        sed -i "s/test_goc_a/prod_goc_a\/$version/g" $storage_file/$file/xml/$config 
        sed -i "s/$test888/$gameSrv/g" $storage_file/$file/xml/$config
        sed -i "s/1015316028501703/$challengeId/g" $storage_file/$file/xml/$config
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
    
    #Upload configuration files to S3
    if [ "$confVersion" = "" ]
    then
    	echo "Do not need to upload configuration files"
    else
    	echo "Uploading configuration files..."
        get_prod_lobby
    	cp $git_dir/config_prod.xml $storage_file/config.xml
    	cp $git_dir/config_prod.js $storage_file/config.js
		cp $git_dir/toMobile_prod.html $storage_file/toMobile.html
		
    	sed -i "s/\$version/$confVersion/g" $storage_file/config.xml
    	sed -i "s/\$version/$confVersion/g" $storage_file/config.js
    	s3cmd put -P --add-header=Cache-Control:no-cache $storage_file/config*  $production/conf/
		s3cmd put -P --add-header=Cache-Control:no-cache $storage_file/toMobile.html  $production/conf/
    fi
}

backup(){
	echo "[`datetime`] $info:starting sync $testing/ to $backup/"
	s3cmd sync -P --add-header=Cache-Control:no-cache --delete-removed --recursive $testing/ $backup/ |tee -a $log_dir/s3cmd.log
	if [ $? != 0 ] 
	then
  	echo "[`datetime`] Failed to backup"  >>$log_dir/$log
  	exit 2
  else
  	echo "[`datetime`] Backup successed"  >>$log_dir/$log
  fi
}  

get_prod_lobby(){
    echo "Get lobby files from Git: release_A..."
    cd $git_dir_root
    git reset --hard
   
    git checkout release_A
    if [ $? != 0 ];then
        echo "Branch checkout failure" >>$log_dir/$log
        exit 1
    fi
    git pull
    if [ $? != 0 ];then
        echo "Git pull failure" >>$log_dir/$log
        exit 1
    fi
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

if [ "$3" = "" ];then
    echo "ERROR:Please input release version"
    exit 1
fi

if [ "$4" = "" ];then
    echo "ERROR:Please confirm release version"
    exit 1
fi

if [ "$3" != "$4" ] ;then
    echo "ERROR:Version doesn't match"
    exit 1
fi

version=$3
confVersion=$5

if [ "$1" = "cp" ] ;then
    case $2 in
             lobby)
                 s3cmd_cp
                     cp_lobby
                 ;;

             casino)
                 s3cmd_cp
                     cp_casino
                 exit 1
                 ;;
                          
             all)
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
                 s3cmd_sync
                     sync_lobby
                 ;;

             casino)
                 s3cmd_sync
                     sync_casino
                 exit 1
                 ;;

             all)
                 s3cmd_sync
                     sync_lobby
                     sync_casino
                 ;;
             *)
                 echo "`basename $0` $1 Usage:{lobby|casino|all}"
    esac

else
    echo "`basename $0` Usage:{cp|sync}"
    exit 1
fi

prod_config

backup