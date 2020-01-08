#!/bin/bash
#-------------------------------------------------------
CUR_PRGDIR=`pwd` 
#Read profile
PROP_FILE="$CUR_PRGDIR/bifang_init_param.conf"
prop_value=""
#---------------------------read file---------------------------------------------------
#echo $CUR_PRGDIR
function read_file(){
	if [ $# != 2 ]
		 then
		 	echo "usage: read_file [prop_name][must_input_flag]"
		 	exit 0 
	fi
	prop_name="$1"
	must_input_flag="$2"
	if [ -z "$(cat $PROP_FILE |grep $prop_name)" ]
		then
			prop_value=""
	else
		temp=`sed -n "/^[ \t]*$prop_name[ \t]*[=].*/p" $PROP_FILE`
		prop_value=`echo ${temp#*=}| sed 's/^[ \t]*//g'|sed 's/[ \t]*$//g'|sed 's/\r//'`
	fi
	if [ "$must_input_flag" = "y" ]
		then
		if [ -z  "$prop_value" ]
			then
			echo -n "${prop_name} can not be empty！"
			exit 0
		fi
	fi
}

read_file "db_name" "n"
db_name="$prop_value"
#-----------------------------------Parameter acquisition------------------------------------------------
read_file "minio_url" "y"
minio_url="$prop_value"
read_file "minio_accessKey" "y"
minio_accessKey="$prop_value"
read_file "minio_secretKey" "y"
minio_secretKey="$prop_value"
read_file "minio_bucketName" "y"
minio_bucketName="$prop_value"
read_file "api_port" "n"
api_port="$prop_value"
read_file "yh_data_url_log" "y"
yh_data_url_log="$prop_value"
#--------------------------------------------------------
read_file "time_zone" "n"
time_zone="$prop_value"
read_file "consul_ip" "n"
consul_ip="$prop_value"
read_file "consul_port" "n"
consul_port="$prop_value"
#--------------------------------api-kafka-------------------------------------------
read_file "api_kafka_servers" "y"
api_kafka_servers="$prop_value"
read_file "api_kafka_groupid" "n"
api_kafka_groupid="$prop_value"
#--------------------------------subid-kafka-------------------------------------------
read_file "subid_kafka_servers" "y"
subid_kafka_servers="$prop_value"
read_file "subid_kafka_topic" "n"
subid_kafka_topic="$prop_value"
read_file "subid_kafka_groupid" "n"
subid_kafka_groupid="$prop_value"
#------------------------t_sys_cfg parameter----------------------------------------
read_file "influx_password" "n"
influx_password="$prop_value"
read_file "influx_user" "n"
influx_user="$prop_value"
read_file "influx_url" "n"
influx_url="$prop_value"
read_file "influx_database" "n"
influx_database="$prop_value"
read_file "oam_api_address" "n"
oam_api_address="$prop_value"
read_file "token_timeout" "n"
token_timeout="$prop_value"
#----------------------------------Modify file parameters-------------------------------------------------------
#---------------Modify time zone-----
update_time(){
	api_time=/home/docker/bifang/api/Dockerfile
	api_dep=/home/docker/bifang/api/deploy-api.sh
	syn_time=/home/docker/bifang/syncredis/Dockerfile
	subid_time=/home/docker/bifang/webfocus/Dockerfile
	sed -i "s%port=.*%port=$api_port%g" $api_dep
	sed -i "s%ENV TimeZone=.*%ENV TimeZone=$time_zone%g" $api_time
	sed -i "s%ENV TimeZone=.*%ENV TimeZone=$time_zone%g" $syn_time
	sed -i "s%ENV TimeZone=.*%ENV TimeZone=$time_zone%g" $subid_time
	sed -i 's/\r$//'  $api_dep
	sed -i 's/\r$//'  $api_time
	sed -i 's/\r$//'  $syn_time
	sed -i 's/\r$//'  $subid_time
}

update_file(){
#--------------------------------Modify related file parameters---------------------------------------------------------
api_config=/home/docker/bifang/api/config/application-dev.properties
syn_config=/home/docker/bifang/syncredis/config/application-dev.properties
webfocus_config=/home/docker/bifang/webfocus/config/application-dev.properties
fqdn_config=/home/docker/categoryinit/config.properties
#---------------------------------Modify API profile------------------------
sed -i "s%spring.datasource.url=.*%spring.datasource.url=jdbc:mysql://mariadb-bifang:$db_port/$db_name?rewriteBatchedStatements=true%g" $api_config 
sed -i "s%server.port=.*%server.port=$api_port%g" $api_config

sed -i "s%spring.kafka.bootstrap-servers=.*%spring.kafka.bootstrap-servers=$api_kafka_servers%g" $api_config 
sed -i "s%kafka.consumer.group.id=.*%kafka.consumer.group.id=$api_kafka_groupid%g" $api_config 

if [ -n "$consul_ip" ]; then
	sed -i "s%consul.ip=.*%consul.ip=$consul_ip%g" $api_config
fi
if [ -n "$consul_port" ]; then
	sed -i "s%consul.port=.*%consul.port=$consul_port%g" $api_config
fi
#----------------------------------Modify synchronization service profile----------------------------------------------------------------------
sed -i "s%spring.datasource.url=.*%spring.datasource.url=jdbc:mysql://mariadb-bifang:$db_port/$db_name?rewriteBatchedStatements=true%g" $syn_config 
#-----------------------------------Modify mapping service profile---------------------------------------------------------------------------------------------
sed -i "s%spring.datasource.url=.*%spring.datasource.url=jdbc:mysql://mariadb-bifang:$db_port/$db_name?rewriteBatchedStatements=true%g" $webfocus_config 
sed -i "s%spring.kafka.bootstrap-servers=.*%spring.kafka.bootstrap-servers=$subid_kafka_servers%g" $webfocus_config
sed -i "s%radius.log.topic=.*%radius.log.topic=$subid_kafka_topic%g" $webfocus_config
sed -i "s%kafka.consumer.group.id=.*%kafka.consumer.group.id=$subid_kafka_groupid%g" $webfocus_config

#------------------------------------Modify service classification profile--------------------------------------------------------------------------------------------------------------
sed -i "s%url=.*true%url=jdbc:mysql://mariadb-bifang:$db_port/$db_name?rewriteBatchedStatements=true%g" $fqdn_config
sed -i "s%password=.*%password=$db_pwd%g" $fqdn_config 
sed -i "s%fileResource=.*%fileResource=/home/ceiec/bifang/category/clf%g" $fqdn_config
#------------------------------------------------------------------------------------------------------------------------
bf_nginx=/home/docker/bifang/bifang-html/nginx.conf
sed -i "s%server.*weight.*;%server bifang-api:$api_port weight=5;%g" $bf_nginx
#-------------------------------------Modify script configuration parameters---------------------------------------------------------------------------------------------------

bifang_init=/home/docker/db_init/bifang_init.sh

create_db=/home/docker/db_init/create_db.sh
sed -i "s%CACERT_URL=.*%CACERT_URL='http://127.0.0.1/v1/policy/profile/trustedcacertobj'%g" $bifang_init 
sed -i "s%KEYRING_URL=.*%KEYRING_URL='http://127.0.0.1/v1/policy/profile/keyringobj'%g" $bifang_init 
sed -i "s%TOKEN_URL=.*/v1%TOKEN_URL='http://127.0.0.1/v1%g" $bifang_init 

sed -i "s%DB_HOST=.*%DB_HOST=127.0.0.1%g" $bifang_init
sed -i "s%DB_PWD=.*%DB_PWD=$db_pwd%g" $bifang_init
sed -i "s%DB_NAME=.*%DB_NAME=$db_name%g" $bifang_init 

db_data=\'\`${db_name}\`\'
sed -i "s%DB_DATA=.*%DB_DATA=$db_data%g" $create_db
sed -i "s%DB_NAME=.*%DB_NAME=$db_name%g" $create_db
sed -i "s%DB_PWD=.*%DB_PWD=$db_pwd%g" $create_db

sed -i 's/\r$//'  $bf_nginx
sed -i 's/\r$//'  $create_db
sed -i 's/\r$//'  $bifang_init
sed -i 's/\r$//'  $fqdn_config
sed -i 's/\r$//'  $webfocus_config
sed -i 's/\r$//'  $syn_config
sed -i 's/\r$//'  $api_config
	update_time
}	
#---------------------------docker install-------------------------------------
install_redis_mariadb () {
netwokr_d=`docker network ls|grep tsg `
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] Create docker container network"
   docker network create -d bridge  tsg
fi

if [ -d "/home/device/mariadb" ];
 then
    echo "----------------------------------------------------------------------"
 else
 echo "[`date '+%Y-%m-%d %T'`] Start extracting device files"
	unzip device.zip -d /home
fi

mariadb_file=/home/device/mariadb/docker-compose.yml
sed -i "s%.*MYSQL_ROOT_PASSWORD=.*%      - MYSQL_ROOT_PASSWORD=$db_pwd%g" $mariadb_file
sed -i "s%.*:3306%      - $db_port:3306%g" $mariadb_file
sed -i 's/\r$//'  $mariadb_file

#mariadb Mirror file
mariadb=`docker images|grep mariadb* ` 
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] Import mariadb Mirror file"
	d_mysql=`cd /home/device/mariadb/ && docker load -i mariadb.tar`
fi
mariadb_ps=`docker ps|grep mariadb* `
if [ $? -ne 0 ]
then
   echo "[`date '+%Y-%m-%d %T'`] start-up mariadb Mirror file"	
	up_mysql=`cd /home/device/mariadb/ && docker-compose up -d`
fi
sleep 10s
#redis Mirror file
redis=`docker images|grep redis* ` 
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] Import redis Mirror file"
	d_redis=`cd /home/device/redis/ && docker load -i redis.tar`
fi  

redis_ps=`docker ps|grep redis* `
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] start-up redis Mirror file"	
	up_redis=`cd /home/device/redis/ && docker-compose up -d`
fi
sleep 10s
}

docker_start () {
which "docker" > /dev/null
if [ $? -eq 0 ]
then
	echo "-----------------docker already installed-------------------"
else
  echo "[`date '+%Y-%m-%d %T'`] Start installation docker"
  dockerPath=/home/docker/docker_init/docker-deploy.sh
	 d_docker=`cd /home/docker/docker_init/ && ./docker-deploy.sh`
   which "docker" > /dev/null
	if [ $? -eq 0 ]
	then
		echo "[`date '+%Y-%m-%d %T'`] docker Successful installation"
		systemctl enable docker
	fi
fi

which "docker-compose" > /dev/null
if [ $? -eq 0 ]
	then
		echo "---------docker-compose Already exist-------------"
	else
	 echo "[`date '+%Y-%m-%d %T'`] Start installation docker-compose"
    cp /home/docker/docker_init/docker-compose /usr/local/bin/
	chmod +x /usr/local/bin/docker-compose
fi
 install_redis_mariadb
 }


#------------------------------------Decompress jar package related files-----------------------------
u_api=/home/bifang/api/
u_syn=/home/bifang/syncredis/
u_suid=/home/bifang/webfocus/

dk_api=/home/docker/bifang/api/
dk_syn=/home/docker/bifang/syncredis/
dk_suid=/home/docker/bifang/webfocus/
api_n=bifang-api.jar
syn_n=syncConfigToRedis.jar
suid_n=mapping-subid-ip.jar
dk_back=/home/docker/bifang/api_back/

unzip_jar(){
	if [ $# != 3 ] && [ $# != 4 ]
		 then
		 	echo "usage: unzip_jar [no_api][cp_path] [jar_name] [back]"
		 	exit 0 
	fi
	no_api=$1
	cp_path=$2
	jar_name=$3
	back_api=$4
	if [ -f "$no_api/$jar_name" ];then
			read -p "$no_api/$jar_name The file already exists. Do you want to replace it y/n：" jary
			if [ $jary = "y" ];then
				  if [ $back_api = 1 ];then
					  	if [ ! -d "$dk_back" ];then
							mkdir -p $dk_back
						fi
				  	 starttime=`date +'%Y%m%d%H%M%S'`
				  	 cp $no_api/$jar_name  $dk_back/bifang_api_$starttime.jar
				  fi
				rm -rf $no_api/$jar_name
				unzip_jar $no_api $cp_path $jar_name
			fi
		else
			if [ -d "$cp_path" ];then
				cp -r  $cp_path/*  $no_api 
			else
				echo "[`date '+%Y-%m-%d %T'`] Unzip the bifang.zip compressed file"
				unzip bifang.zip -d /home
				cp  -r $cp_path/*  $no_api 
			fi
		fi
}

#------------------------------------Image file installation-------------------------------------------------------
dockerInit(){
	update_cfg
docker_count=`ps -ef|grep docker|grep -v grep`
if [ $? -ne 0 ];then
	echo "[`date '+%Y-%m-%d %T'`] Start docker service"
	systemctl stop docker
	systemctl start docker
fi
centos=`docker images|grep centos* ` 
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] Import centos-bifang image file"
	d_centos=`cd /home/docker/centos/ && docker load -i centos-bifang.tar`
fi
jdk=`docker images|grep jdk* ` 
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] Install the JDK image file"
	d_jdk=`cd /home/docker/jdk && docker build -t jdk:1.8.0_73 .`
fi
nginx=`docker images|grep nginx* ` 
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] Install nginx image file" 
	d_nginx=`cd /home/docker/bifang/nginx/ && docker load -i nginx.tar`
fi
echo "[`date '+%Y-%m-%d %T'`] Install and start api service"
	d_api=`cd /home/docker/bifang/api/ && ./deploy-api.sh deployImagesAndStartContainer`	
echo "[`date '+%Y-%m-%d %T'`] Install and start bifang-html"
	d_ui=`cd /home/docker/bifang/bifang-html/ && ./deploy-bifangHtml.sh deployImagesAndStartContainer`
echo "[`date '+%Y-%m-%d %T'`] Install and start syncredis service"
	d_syn=`cd /home/docker/bifang/syncredis/ && ./deploy-syncredis.sh deployImagesAndStartContainer`
echo "[`date '+%Y-%m-%d %T'`] Install and start mapping-subid-ip service"
	d_subid=`cd /home/docker/bifang/webfocus/ && ./deploy-webfocus.sh deployImagesAndStartContainer`
	cp_html
	api_check
}

cp_html(){
	ui_path=/home/ceiec/bifang/ui/bifang-html
	dk_ui=/home/bifang/bifang-html
	dk_html=/home/docker/bifang/ui_back/
	if [ ! -d "$ui_path/static" ];then
			if [ -d "$dk_ui/static" ];then
				cp -r $dk_ui/* $ui_path/
			fi
		else 
			read -p "UI interface file already exists, do you want to replace it y/n：" htmly
			if [ $htmly = "y" ];then
				if [ ! -d "$dk_html" ];then
						mkdir -p $dk_html
				fi
				starttime=`date +'%Y%m%d%H%M%S'`
				zip -q -r $dk_html/html_$starttime.zip $ui_path/*
				rm -rf $ui_path/*
				cp_html
			fi
	fi	
}

api_check(){
	echo "[`date '+%Y-%m-%d %T'`] Check whether API service starts successfully。。。"
	sleep 1m
	#TOKEN 获取接口URL
	TOKEN_URL="http://127.0.0.1/v1/user/login?username=admin&password=admin"
	TOKEN=$(curl -s -X POST $TOKEN_URL|grep 'token'|awk -F':' '{print $2}'|awk -F'"' '{print $2}')
	echo "user login,token:${TOKEN}"
	if [ -z "$TOKEN" ]; then
		echo "[`date '+%Y-%m-%d %T'`] API service token acquisition failed"
		read -p "(Note: if the API service starts slowly, it will fail to get the token. You can get it again) Please confirm whether to get it again token  y/n：" api_token
		if [ $api_token = 'y' ];then 
			api_check
			else
				echo "After checking the API service log（log Catalog /home/ceiec/bifang/api/logs），Re execute script"
		fi
	else 
		echo "[`date '+%Y-%m-%d %T'`] API service started successfully"
		cer_sql="select count(*)  as '' from pxy_profile_trusted_ca_cert"
		cert_count=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name -P$db_port -e "${cer_sql}"`
		if [ $cert_count -gt 5 ];then 
			category_init
		else
			cert_init
		fi 
	fi
}


#--------------------------------Extract docker file--------------------------------------
unzip_inIt(){
	echo "[`date '+%Y-%m-%d %T'`] Start extracting docker file"
	unzip docker.zip -d /home
	if [ $? -eq 0 ]
	then
	echo "[`date '+%Y-%m-%d %T'`] Decompression complete"
			unzip_jar $dk_api $u_api $api_n 0
			unzip_jar $dk_syn $u_syn $syn_n 0 
			unzip_jar $dk_suid $u_suid $suid_n 0

		find /home/docker/* -name "*.sh" -type f  -exec chmod 755 \{\} \;

		docker_start

		config
	else
	echo "[`date '+%Y-%m-%d %T'`] Decompression failed"
	fi
}

#-------------------------------Modify t_sys_cfg parameters-------------------------------
update_cfg(){
	if [ -n "$yh_data_url_log" ]; then
		yh_sql="update t_sys_cfg  set cfg_value='$yh_data_url_log' where cfg_name='yh_data_url_log'"
		db_yh=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name -P$db_port -e "${yh_sql}"`
	fi

	if [ -n "$influx_password" ]; then
		ipwd_sql="update t_sys_cfg  set cfg_value='$influx_password' where cfg_name='influx_password'"
		db_ipwd=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name -P$db_port -e "${ipwd_sql}"`
	fi

	if [ -n "$influx_user" ]; then
		iusr_sql="update t_sys_cfg  set cfg_value='$influx_user' where cfg_name='influx_user'"
		db_iusr=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name -P$db_port -e "${iusr_sql}"`
	fi

	if [ -n "$influx_url" ]; then
		iurl_sql="update t_sys_cfg  set cfg_value='$influx_url' where cfg_name='influx_url'"
		db_iurl=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name -P$db_port -e "${iurl_sql}"`
	fi

	if [ -n "$influx_database" ]; then
		idb_sql="update t_sys_cfg  set cfg_value='$influx_database' where cfg_name='influx_database'"
		db_idb=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name -P$db_port -e "${idb_sql}"`
	fi

	if [ -n "$oam_api_address" ]; then
		oam_sql="update t_sys_cfg  set cfg_value='$oam_api_address' where cfg_name='oam_api_address'"
		db_oam=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name -P$db_port -e "${oam_sql}"`
	fi


	if [ -z "$token_timeout" ]; then
		token_timeout=1800
	fi

	token_sql="update t_sys_cfg  set cfg_value='$token_timeout' where cfg_name='token_timeout'"
	db_token=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name -P$db_port -e "${token_sql}"`

	murl="update t_sys_cfg  set cfg_value='$minio_url' where cfg_name='minio_url';update t_sys_cfg  set cfg_value='$minio_accessKey' where cfg_name='minio_accessKey';update t_sys_cfg  set cfg_value='$minio_secretKey' where cfg_name='minio_secretKey';update t_sys_cfg  set cfg_value='$minio_bucketName' where cfg_name='minio_bucketName'"
	db_m=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name -P$db_port -e "${murl}"`
}

#------------------------------Certificate initialization-----------------------------------
cert_init(){

echo "[`date '+%Y-%m-%d %T'`] Certificate initialization"
	d_cert=`cd /home/docker/db_init && ./bifang_init.sh`
	cert_falg=`grep -i "true" /home/ceiec/bifang/init.log|wc -l`
	if [ $cert_falg -gt 0 ];then		
		cert_f=`grep -i "false" /home/ceiec/bifang/init.log|wc -l`
		if [ $cert_f -gt 0 ];then
			echo "[`date '+%Y-%m-%d %T'`] minio parameter Account ：$minio_accessKey  Password ：$minio_secretKey url:$minio_url "
			echo "[`date '+%Y-%m-%d %T'`] The initial certificate is abnormal. Please check whether the $minio_bucketName bucket in Minio is created and whether the read-write permission is added"
			minio_err
		else
			echo "[`date '+%Y-%m-%d %T'`] Certificate initialization Execution completed"
			category_init
		fi	
	else 
		echo "[`date '+%Y-%m-%d %T'`] minio parameter Account ：$minio_accessKey  Password ：$minio_secretKey url:$minio_url "
		echo "The initial certificate is abnormal. Please check whether the $minio_bucketName bucket in Minio is created and whether the read-write permission is added"
		 minio_err
	fi

}

minio_err(){
	echo "1、Reexecute initialization certificate"
	echo "2、Skip certificate initialization and proceed to the next step"
	read -p "Please enter the above number to perform the operation：" mnum 
	rm -rf /home/ceiec/bifang/init.log
	if [ $mnum -eq "1" ];then 
		cert_init
	elif [ $mnum -eq "2" ];then
		category_init
	else 
	  echo "Please input again as follows"
		minio_err
	fi 
}

category_init(){
	fqdn_sql="select count(*)  as '' from tsg_obj_fqdn_cat"
	fqdns=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name  -P$db_port -e "${fqdn_sql}"`
	if [ $fqdns -gt 5 ];then 
		echo  "Script Execution completed"
	else
		echo "[`date '+%Y-%m-%d %T'`] Classification service initialization"
        echo "[`date '+%Y-%m-%d %T'`] Install and start the service categorizer"
	    d_sync=`cd /home/docker/categoryinit && ./deploy-category.sh deployImagesAndStartContainer`
		echo "[`date '+%Y-%m-%d %T'`] Service classification data initialization in progress。。。"
		sleep 1m
	fqdn_count=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name  -P$db_port -e "${fqdn_sql}"`
		if [ $fqdn_count -gt 5 ];then 
			echo  "Script Execution completed"
		else
			echo  "Service classification initialization failed"
		fi

	fi
}

#---------------------------------Create database-------------------------------------------------
db_init(){
		db_care=`mysql -h127.0.0.1 -uroot -p$db_pwd  -P$db_port -e "use $db_name"`
		if [ $? -eq 0 ];then
			read -p  "Database $db_name already exists, do you want to recreate and overwrite this database y/n："  dby
			if [ $dby = "y" ];then 
				echo "[`date '+%Y-%m-%d %T'`] Create $db_name database"
				db_in=`cd /home/docker/db_init/ && ./create_db.sh`
				echo "$db_in"
				dockerInit
			else 
				dockerInit
			fi
		else
			echo "[`date '+%Y-%m-%d %T'`] Create $db_name database"
			db_in=`cd /home/docker/db_init/ && ./create_db.sh`
			echo "$db_in"
			dockerInit
		fi
}

#-----------------------------------Check Minio parameters-----------------------------------------
m_check(){
	minurl=$(curl -X POST --header "Accept: */*" -H "Content-Type: application/json"  --data '{"id": 1,"jsonrpc": "2.0", "params": {"username": "'"$minio_accessKey"'", "password": "'"$minio_secretKey"'"},"method": "Web.Login" }' ''"$minio_url/minio/webrpc"'')
	result=$(echo $minurl|grep 'token'|awk -F'token":"' '{print $2}'|awk -F'",' '{print $1}')
	if [[ $result != "" ]];then
		echo  "[`date '+%Y-%m-%d %T'`] Minio connection parameters are normal"
		update_file
	else 
		echo "[`date '+%Y-%m-%d %T'`] minio parameter account：$minio_accessKey password：$minio_secretKey URL:$minio_url "
		mess=$(echo $minurl|grep 'message'|awk -F'message":"' '{print $2}'|awk -F'",' '{print $1}')
		if [ -z "$mess" ]; then
			echo "[`date '+%Y-%m-%d %T'`] Mini parameter connection failed"
		else
			echo "[`date '+%Y-%m-%d %T'`] The connection of Minio parameter is abnormal：$mess"
		fi
		read -p "Please re-enter the account password URL of Mino, enter the number 1 to skip the detection and continue with the next steps：" m_accessKey m_secretKey m_url
		if [ $m_accessKey = 1 ];then
			echo "[`date '+%Y-%m-%d %T'`] Skip Minio detection"
			update_file
			else
				minio_url=$m_url
				minio_accessKey=$m_accessKey
				minio_secretKey=$m_secretKey
				m_check
			fi
	fi
}

redad_contans(){
db_pwd=bfzdjizhi
db_port=3306
if [ -z "$db_name" ]; then
		db_name=tsg-bifang
	fi
	if [ -z "$time_zone" ]; then
		time_zone=`timedatectl | grep Time |awk -F'zone: ' '{print $2}'|awk -F'(' '{print $1}'`
	fi
	if [ -z "$api_port" ]; then
		api_port=8080
	fi
	if [ -z "$api_kafka_groupid" ]; then
		api_kafka_groupid=tsg-consumer-cert
	fi

	if [ -z "$subid_kafka_topic" ]; then
		subid_kafka_topic=RADIUS-RECORD-LOG
	fi

	if [ -z "$subid_kafka_groupid" ]; then
		subid_kafka_groupid=mapping-subid-ip
	fi	

}

config(){
	dbmysql=0
	which "mysql" > /dev/null
	if [ $? -eq 0 ];then
	   m_check
		db_init
	else 
		echo "[`date '+%Y-%m-%d %T'`] Install MySQL client service"
		rpm -ivh /home/docker/db_init/db-client/*.rpm --force --nodeps
		which "mysql" > /dev/null
		if [ $? -eq 0 ];then
			echo "[`date '+%Y-%m-%d %T'`] MySQL client service installed successfully"
			m_check
			db_init
		else 
			echo "[`date '+%Y-%m-%d %T'`] MySQL client service offline installation failed"
			echo "[`date '+%Y-%m-%d %T'`] MySQL client online installation"
			yum install mysql  -y	
		which "mysql" > /dev/null
		if [ $? -eq 0 ];then
			echo "[`date '+%Y-%m-%d %T'`] MySQL client service installed successfully"
			m_check
			db_init
		else 
			dbmysql=1
			echo "[`date '+%Y-%m-%d %T'`] MySQL Online installation of client service failed. Please install MySQL remote client manually and try again"
			fi
		fi
	fi
}


bifang_init_start(){
	redad_contans
	if [ -d "/home/docker" ];
	then
		read -p "[`date '+%Y-%m-%d %T'`] docker The directory already exists. Please confirm whether to delete it and extract the file again y/n ：" ziInit
		if [ $ziInit = "y" ];then
			rm -rf /home/docker 
			unzip_inIt
		else
		find /home/docker/* -name "*.sh" -type f  -exec chmod 755 \{\} \;
		unzip_jar $dk_api $u_api $api_n 0
		unzip_jar $dk_syn $u_syn $syn_n 0
		unzip_jar $dk_suid $u_suid $suid_n 0
		echo "[`date '+%Y-%m-%d %T'`] Start checking environment configuration"
		docker_start
		echo "[`date '+%Y-%m-%d %T'`] Start checking bifang_init_param.conf configuration file parameters"
			config
		fi
	else
		unzip_inIt
	fi
}

update_ui(){
	bf_nginx=/home/docker/bifang/bifang-html/nginx.conf
	if [ -f "$bf_nginx" ];then
		read -p "Please enter the service address of the UI interface to access the API, and the primary access IP address ："  api_nginx back_nginx
			sed -i "s%server.*weight.*;%server $api_nginx weight=5;%g" $bf_nginx
			 if [ -n "$back_nginx" ]; then
				sed -i "s%server.*:.*backup;%server $back_nginx backup;%g" $bf_nginx
			fi
		sed -i 's/\r$//'  $bf_nginx
		echo "Bi Fang API service is restarting"
		d_ui=`cd /home/docker/bifang/bifang-html/ && ./deploy-bifangHtml.sh deployImagesAndStartContainer`
		echo "Bi Fang API service started successfully"
	  else
		echo "Please install API service and try again!"
	fi
}
update_api(){
	echo "1、Update API service jar（Please put the file in /home/bifang/api/）"
	echo "2、Update synchronization service（Please put the file in /home/bifang/syncredis/）"
	echo "3、Update UI interface file（Please put the file in /home/bifang/bifang-html/）"
	read -p "Please enter the above number to perform the operation：" api_num
	if [ -d "$dk_api" ];then
		if [ $api_num = 1 ];then
			unzip_jar $dk_api $u_api $api_n 1
			echo "Bi Fang API service is restarting"
				d_api=`cd /home/docker/bifang/api/ && ./deploy-api.sh deployImagesAndStartContainer`
				sleep 2m
			echo "Bi Fang API service started"
		elif [ $api_num = 2 ];then
			unzip_jar $dk_syn $u_syn $syn_n 0
			echo "The synchronization service of Bi Fang is being restarted"
				d_api=`cd /home/docker/bifang/syncredis/ && ./deploy-syncredis.sh deployImagesAndStartContainer`
				sleep 1m
			echo "Start of Bi Fang synchronization service completed"
		elif [ $api_num = 3 ];then
			cp_html
			echo "Bi Fang UI update completed"
	     else 
			echo "Exit operation！"
		fi
	else
		echo "Please install API service and try again!"
	fi
}

deldocker(){
	echo "Stop all docker containers"
	docker stop $(docker ps -a -q)
	echo "Delete all stopped docker containers"
	docker rm -f $(docker ps -aq)
}

del_docker(){
	echo "1、Delete the docker image file with < none > exception"
	echo "2、Delete all docker image files"
	read -p "Please input the above digital operation：" dk_num
	if [ $dk_num = 1 ];then
		none=`docker images|grep none|wc -l`
		if [ $none -gt 0 ];then
			deldocker
			echo "Delete all tag tags as the image of none"
			docker images|grep none|awk '{print $3 }'|xargs docker rmi
			echo "Delete successfully! Please reinstall the API service"
			echo "-------------------------------operation list---------------------------------------"
			bf_start
		else
			echo "There is no docker image file with < none > exception"
		fi
	elif [ $dk_num = 2 ];then
			deldocker
			echo "Delete all docker image files"
			docker rmi $(docker images -q)
			echo "Delete successfully! Please reinstall the API service"
			echo "-------------------------------operation list---------------------------------------"
			bf_start
	else
		del_docker
	fi
}

up_network(){
	echo "Detect docker network environment"
	docker_ipv=$( cat /usr/lib/sysctl.d/00-system.conf |grep net.ipv4.ip_forward=1|wc -l )
	if [ $docker_ipv = 0 ]
	  then 
		echo "net.ipv4.ip_forward=1" >> /usr/lib/sysctl.d/00-system.conf
		echo "Restart network service"
	    service network restart
	   which "docker" > /dev/null
			if [ $? -eq 0 ]
			then
				echo "Restart docker service"
				systemctl restart docker
				echo "Execution completed！"
			else 
				echo "Execution completed！"
			fi	
	   else 
		echo "Detection completed！"
	fi
}

api_uninstall(){
	echo "Cleaning up。。。"
	rm -rf /home/docker
	rm -rf /home/bifang
	rm -rf /home/ceiec/bifang
	cp -r /home/ceiec/mariadb  /home/ceiec/mariadb_back
	rm -rf /home/ceiec/mariadb
	rm -rf /home/ceiec/reids
	deldocker
	echo "Delete all docker image files"
	docker rmi $(docker images -q)
	echo "Delete successfully! Please reinstall the API service"
}

kill_port(){
	read -p "Please enter the port number to stop：" kport
	for i in `lsof -i tcp:$kport | awk '{print $2}' | grep -v 'PID'`;
	do kill -9 $i
	done
	echo "Port $kport stopped"
}

bf_start(){
	echo "1、Install and deploy API service"
	echo "2、Adjust UI API access address"
	echo "3、Update API service"
	echo "------------------------------Handling of common problems--------------------------------------------"
	echo "a、Delete docker image file (there are image files of < none >)"
	echo "b、Network disable docker image installation exception（IPv4 forwarding is disabled. Networking will not work.）"
	echo "c、docker port occupation error"
	echo "d、One click deletion (delete the extracted docker, Bifang directory and docker image file)"
	echo "------------------------------------------------------------------------------"
	read -p "Please enter the above number to perform the operation：" db_num
	if [ $db_num = "1" ];then
		up_network
		bifang_init_start
	elif [ $db_num = "2" ];then
		update_ui  
	elif [ $db_num = "3" ];then
		echo "------------------------Update service catalog----------------------------"
		update_api
	elif [ $db_num = "a" ];then
		which "docker" > /dev/null
		if [ $? -eq 0 ]
		then
			del_docker
		else 
			echo "Docker service does not exist, please install API service first"
		fi
	elif [ $db_num = "b" ];then
		up_network
	elif [ $db_num = "c" ];then
		kill_port		
	elif [ $db_num = "d" ];then
		which "docker" > /dev/null
		if [ $? -eq 0 ]
		then
			api_uninstall
		else 
			echo "Docker service does not exist, please install API service first"
		fi
	  else 
	  echo "-------------------------------operation list---------------------------------------"
	   bf_start
	fi
}
echo "-------------------------------operation list---------------------------------------"
bf_start

