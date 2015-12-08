#! /bin/bash
# production flash cpoy and synchronization script


##
config_dir=/home/qa/deployment/build/goc_b/onlineGameFlash.war/lobby
storage_file=/home/qa/ProductionPackage/build/goc_b/onlineGameFlash.war/lobby
comp_dir=/home/qa/ProductionPackage/build/goc_b/onlineGameFlash.war/comp_conf
salt_package_dir=/srv/salt/packages/gocb
client_bak_dir=/home/qa/deployment/bak/gocb/
config=configuration.xml

##
s3url=s3://aspect-gaming-flash
testing=$s3url/test_goc_b
production=$s3url/prod_goc_b
#backup=$s3url/test_goc_b_compatibility
backup=$s3url/miles/test_goc_b_compatibility
log_dir=/home/qa/ProductionPackage/log
log=`basename $0|awk -F '.' '{print $1".log"}'`
command=`which s3cmd`

error=ERROR
info=INFO

##
gameSrv=www.grandorientcasino.com
pokerServer=54.67.76.118
bossServer=52.8.243.151
#deploy_clientServer=Prod-GOC-Game-SrvB02,Prod-GOC-Game-SrvB02
deploy_clientServer=Test-GoPoker-Srv1,Test-GoPoker-Srv1
tulpes=(en_US es_ES th_TH zh_TW)
test888=test888.grandorientcasino.com
testip=52.8.220.85
gaID=Prod_GOC_B
challengeId=880248862062203


## main function
datetime(){
     date=`date  '+%Y-%m-%d %H:%M:%S'`
     echo $date
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


create_prod_config() {

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
        sed -i "s/test_goc_b/prod_goc_b\/$version/g" $storage_file/$file/xml/$config 
        sed -i "s/$test888/$gameSrv/g" $storage_file/$file/xml/$config
        sed -i "s/1015316028501703/$challengeId/g" $storage_file/$file/xml/$config
        sed -i "s/$testip:8124/$pokerServer:8124/g" $storage_file/$file/xml/$config 
        sed -i "s/http:\/\/.*:8080/http:\/\/$bossServer:8080/g" $storage_file/$file/xml/$config 
        sed -i "/gameAnalytics/s/gaID=..*gaVersion/gaID=\"$gaID\" gaVersion/g" $storage_file/$file/xml/$config

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

backend_deploy(){

   #Upload configuration files to S3

    echo "Uploading configuration files..."
	#rm old version directory
	if [  -d "$salt_package_dir/client" ]; then  
	  rm -rf "$salt_package_dir/client"  
	fi 
	
    #get files form test environment
    rsync -vzrtopg --delete --progress qa@$testip::DeploymentHome/apache-tomcat/webapps/client  $salt_package_dir > /tmp/sync_client.log 2>&1
   
   
    mv $salt_package_dir/client/config_prod.xml $salt_package_dir/client/config.xml
    mv $salt_package_dir/client/config_prod.js $salt_package_dir/client/config.js
  
	
    sed -i "s/\$version/$version/g" $salt_package_dir/client/config.xml
    sed -i "s/\$version/$version/g" $salt_package_dir/client/config.js

	#make tar in /srv/salt/package/gocb/client.tar.gz
	cd $salt_package_dir
    tar zcvfP client.tar.gz client
    MYDATE=`date +%y%m%d`
    cp client.tar.gz $client_bak_dir/client_$MYDATE.tar.gz
    
	echo "Start update client to $deploy_clientServer "
    arr_server=(${deploy_clientServer//,/ })
    for deploy_clientServer_one in "${arr_server[@]}"
    do    
        salt_update=`salt "$deploy_clientServer_one" state.sls sls.upload pillar='{'fileName': { client: client.tar.gz }, 'project_name': gocb,'desc_dir': /srv/apache-tomcat/webapps}'`
        if [ `echo $salt_update | awk '{print $(NF-5)}'` = "0" ]
            then
            echo ${salt_update##*Summary}
            echo "update client to $deploy_clientServer_one Success"
            echo "Start deploy client to $deploy_clientServer_one "
            salt_deploy=`salt "$deploy_clientServer_one" state.sls sls.deploy pillar='{'fileName': { client: client.tar.gz },'project_name': gocb,'desc_dir': /srv/apache-tomcat/webapps}'`
                if [ `echo $salt_deploy | awk '{print $(NF-5)}'` = "0" ]
                    then
                    echo ${salt_deploy##*Summary}
                    echo "deploy client to $deploy_clientServer_one  Success"
                else				
                    echo "ERROR run salt update Failed "
                    echo "$salt_deploy"
                    exit 2
                fi  
        else
            echo "ERROR run salt update Failed "
            echo `echo $salt_update | awk '{print $(NF-5)}'`
            echo "$salt_update"
            exit 2
        fi
    done
     
}



backup2comp(){
	echo "[`datetime`] $info:starting sync $testing/ to $backup/"
	s3cmd sync -P --add-header=Cache-Control:no-cache --delete-removed --recursive $testing/ $backup/ |tee -a $log_dir/s3cmd.log
	if [ $? != 0 ] 
		then
	  	echo "[`datetime`] Failed to backup"  >>$log_dir/$log
	  	exit 2
	else
		echo "[`datetime`] Backup successed"  >>$log_dir/$log
	fi

	####################copy local xml files ,update to s3#########################

    for file in "${tulpes[@]}" 
    do
        if [ ! -d $comp_dir/$file/xml ]
        then
            mkdir -p $comp_dir/$file/xml
        fi
        cp $config_dir/$file/xml/$config $comp_dir/$file/xml/
        sed -i "s/test_goc_b/test_goc_b_compatibility/g" $comp_dir/$file/xml/$config 

        s3cmd put -P --add-header=Cache-Control:no-cache $comp_dir/$file/xml/$config  $backup/lobby/$file/xml/ |tee -a $log_dir/s3cmd.log
        if [ $? != 0 ]
        then
            echo "[`datetime`] $error:put $backup/lobby/$file/xml failure"
            echo "[`datetime`] $error:put $backup/lobby/$file/xml failure" >>$log_dir/$log
            exit 2
        else
            echo "[`datetime`] $info:put $backup/lobby/$file/xml success"
            echo "[`datetime`] $info:put $backup/lobby/$file/xml success"  >>$log_dir/$log
        fi
    done
	


}



#######################################Main Program####################################
rm -rf $log_dir/s3cmd.log
echo "$1 $2 $3"

if [ "$1" = "" ];then
    echo "`basename $0` $1 Usage:{1_casino|2_lobby|3_client}"
    exit 1
fi

if [ "$2" = "" ];then
    echo "ERROR:Please input release version"
    exit 1
fi

if [ "$3" = "" ];then
    echo "ERROR:Please confirm release version"
    exit 1
fi

if [ "$2" != "$3" ] ;then
    echo "ERROR:Version doesn't match"
    exit 1
fi

version=$2

get_str=$1
arr=(${get_str//,/ })
for choose_one in "${arr[@]}"

do
    case $choose_one in
            2_lobby)
                s3cmd_sync
                    sync_lobby
				create_prod_config
                ;;
    
            1_casino)
                s3cmd_sync
                    sync_casino
		#prod_config
                ;;
    
           3_client)
                backend_deploy
                ;;
            *)
                echo "`basename $0` $1 Usage:{1_casino|2_lobby|3_client}"
                exit 1
    esac
done

if [ "$1" != "3_client" ] ;then
  backup2comp
fi
