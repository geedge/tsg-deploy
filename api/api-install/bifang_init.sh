#!/bin/bash
#-------------------------------------------------------
CUR_PRGDIR=`pwd` #当前文件的路径
#读取配置文件
PROP_FILE="$CUR_PRGDIR/bifang_init_param.conf"
prop_value=""
#---------------------------读取文件---------------------------------------------------functions
#echo $CUR_PRGDIR
function read_file(){
	if [ $# != 2 ]
		 then
		 	echo "usage: read_file [prop_name][must_input_flag]"
		 	exit 0 
	fi
	prop_name="$1"
	must_input_flag="$2"
	#echo "modify_file $prop_name $prop_value"
	if [ -z "$(cat $PROP_FILE |grep $prop_name)" ]
		then
			prop_value=""
	else
		#正则匹配
		temp=`sed -n "/^[ \t]*$prop_name[ \t]*[=].*/p" $PROP_FILE`
		#截取对应的值，并去除首尾空格
		prop_value=`echo ${temp#*=}| sed 's/^[ \t]*//g'|sed 's/[ \t]*$//g'|sed 's/\r//'`
	fi
	#判断是否为必填项
	if [ "$must_input_flag" = "y" ]
		then
		if [ -z  "$prop_value" ]
			then
			echo -n "${prop_name} can not be empty！"
			exit 0
		fi
	fi
}
#-----------------------------------参数获取------------------------------------------------
read_file "db_pwd" "y"
db_pwd="$prop_value"
read_file "db_name" "y"
db_name="$prop_value"
read_file "db_port" "n"
db_port="$prop_value"
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
#--------------------------------kafka-------------------------------------------
read_file "kafka_servers" "y"
kafka_servers="$prop_value"
read_file "kafka_groupid" "n"
kafka_groupid="$prop_value"
#------------------------t_sys_cfg参数----------------------------------------
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
#----------------------------------修改文件参数-------------------------------------------------------
#---------------修改时区-----
update_time(){
	api_time=/home/docker/bifang/api/Dockerfile
	syn_time=/home/docker/bifang/syncredis/Dockerfile
	subid_time=/home/docker/bifang/webfocus/Dockerfile
	sed -i "s%port=.*%port=$api_port%g" $api_time
	sed -i "s%ENV TimeZone=.*%ENV TimeZone=$time_zone%g" $api_time
	sed -i "s%ENV TimeZone=.*%ENV TimeZone=$time_zone%g" $syn_time
	sed -i "s%ENV TimeZone=.*%ENV TimeZone=$time_zone%g" $subid_time
	sed -i 's/\r$//'  $api_time
	sed -i 's/\r$//'  $syn_time
	sed -i 's/\r$//'  $subid_time
}

update_file(){
#--------------------------------修改相关文件参数---------------------------------------------------------
api_config=/home/docker/bifang/api/config/application-dev.properties
syn_config=/home/docker/bifang/syncredis/config/application-dev.properties
webfocus_config=/home/docker/bifang/webfocus/config/application-dev.properties
fqdn_config=/home/docker/categoryinit/config.properties
#---------------------------------修改api配置文件------------------------
sed -i "s%spring.datasource.url=.*%spring.datasource.url=jdbc:mysql://mariadb-bifang:$db_port/$db_name?rewriteBatchedStatements=true%g" $api_config 
sed -i "s%spring.datasource.password=.*%spring.datasource.password=$db_pwd%g" $api_config 
sed -i "s%server.port=.*%server.port=$api_port%g" $api_config

sed -i "s%spring.kafka.bootstrap-servers=.*%spring.kafka.bootstrap-servers=$kafka_servers%g" $api_config 
sed -i "s%kafka.consumer.group.id=.*%kafka.consumer.group.id=$kafka_groupid%g" $api_config 

if [ -n "$consul_ip" ]; then
	sed -i "s%consul.ip=.*%consul.ip=$consul_ip%g" $api_config
fi
if [ -n "$consul_port" ]; then
	sed -i "s%consul.port=.*%consul.port=$consul_port%g" $api_config
fi

#----------------------------------修改syn同步服务配置文件----------------------------------------------------------------------
sed -i "s%spring.datasource.url=.*%spring.datasource.url=jdbc:mysql://mariadb-bifang:$db_port/$db_name?rewriteBatchedStatements=true%g" $syn_config 
sed -i "s%spring.datasource.password=.*%spring.datasource.password=$db_pwd%g" $syn_config 
#-----------------------------------修改映射服务配置文件---------------------------------------------------------------------------------------------
sed -i "s%spring.datasource.url=.*%spring.datasource.url=jdbc:mysql://mariadb-bifang:$db_port/$db_name?rewriteBatchedStatements=true%g" $webfocus_config 
sed -i "s%spring.datasource.password=.*%spring.datasource.password=$db_pwd%g" $webfocus_config  
#------------------------------------修改服务分类配置文件--------------------------------------------------------------------------------------------------------------
sed -i "s%url=.*true%url=jdbc:mysql://mariadb-bifang:$db_port/$db_name?rewriteBatchedStatements=true%g" $fqdn_config 
sed -i "s%password=.*%password=$db_pwd%g" $fqdn_config
sed -i "s%fileResource=.*%fileResource=/home/ceiec/bifang/category/clf%g" $fqdn_config

#-------------------------------------修改脚本配置参数---------------------------------------------------------------------------------------------------
#证书脚本参数修改
bifang_init=/home/docker/db_init/bifang_init.sh
#数据库创建脚本修改
create_db=/home/docker/db_init/create_db.sh
sed -i "s%CACERT_URL=.*%CACERT_URL='http://127.0.0.1/v1/policy/profile/trustedcacertobj'%g" $bifang_init 
sed -i "s%KEYRING_URL=.*%KEYRING_URL='http://127.0.0.1/v1/policy/profile/keyringobj'%g" $bifang_init 
sed -i "s%TOKEN_URL=.*/v1%TOKEN_URL='http://127.0.0.1/v1%g" $bifang_init 

sed -i "s%DB_HOST=.*%DB_HOST=127.0.0.1%g" $bifang_init
sed -i "s%DB_PWD=.*%DB_PWD=$db_pwd%g" $bifang_init
sed -i "s%DB_NAME=.*%DB_NAME=$db_name%g" $bifang_init 
#初始化数据库脚本修改
db_data=\'\`${db_name}\`\'
sed -i "s%DB_DATA=.*%DB_DATA=$db_data%g" $create_db
sed -i "s%DB_NAME=.*%DB_NAME=$db_name%g" $create_db
sed -i "s%DB_PWD=.*%DB_PWD=$db_pwd%g" $create_db

sed -i 's/\r$//'  $create_db
sed -i 's/\r$//'  $bifang_init
sed -i 's/\r$//'  $fqdn_config
sed -i 's/\r$//'  $webfocus_config
sed -i 's/\r$//'  $syn_config
sed -i 's/\r$//'  $api_config
	update_time
}	
#---------------------------docker安装-------------------------------------
install_redis_mariadb () {
netwokr_d=`docker network ls|grep tsg `
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] 创建docker容器网络"
   docker network create -d bridge  tsg
fi

if [ -d "/home/device/mariadb" ];
 then
    echo "--------------------------------------"
 else
 echo "[`date '+%Y-%m-%d %T'`] 开始解压device文件"
	unzip device.zip -d /home
fi

mariadb_file=/home/device/mariadb/docker-compose.yml
sed -i "s%.*MYSQL_ROOT_PASSWORD=.*%      - MYSQL_ROOT_PASSWORD=$db_pwd%g" $mariadb_file
sed -i "s%.*:3306%      - $db_port:3306%g" $mariadb_file
sed -i 's/\r$//'  $mariadb_file

#mariadb镜像文件
mariadb=`docker images|grep mariadb* ` 
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] 导入mariadb镜像文件"
	d_mysql=`cd /home/device/mariadb/ && docker load -i mariadb.tar`
fi
mariadb_ps=`docker ps|grep mariadb* `
if [ $? -ne 0 ]
then
   echo "[`date '+%Y-%m-%d %T'`] 启动mariadb镜像文件"	
	up_mysql=`cd /home/device/mariadb/ && docker-compose up -d`
fi
sleep 10s
#redis镜像文件
redis=`docker images|grep redis* ` 
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] 导入redis镜像文件"
	d_redis=`cd /home/device/redis/ && docker load -i redis.tar`
fi  

redis_ps=`docker ps|grep redis* `
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] 启动redis镜像文件"	
	up_redis=`cd /home/device/redis/ && docker-compose up -d`
fi
sleep 10s
}

docker_start () {
#判断docker是否安装
which "docker" > /dev/null
if [ $? -eq 0 ]
then
	echo "-----------------docker已安装-------------------"
else
#执行脚本文件安装docker
  echo "[`date '+%Y-%m-%d %T'`] 开始安装docker"
  dockerPath=/home/docker/docker_init/docker-deploy.sh
	 d_docker=`cd /home/docker/docker_init/ && ./docker-deploy.sh`
   which "docker" > /dev/null
	if [ $? -eq 0 ]
	then
		echo "[`date '+%Y-%m-%d %T'`] docker安装成功"
	fi
fi

which "docker-compose" > /dev/null
if [ $? -eq 0 ]
	then
		echo "---------docker-compose已存在-------------"
	else
	 echo "[`date '+%Y-%m-%d %T'`] 开始安装docker-compose"
    cp /home/docker/docker_init/docker-compose /usr/local/bin/
	chmod +x /usr/local/bin/docker-compose
fi
 install_redis_mariadb
 }


#------------------------------------解压jar包相关文件-----------------------------
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
	#判断docker目录是否存在jar
	no_api=$1
	cp_path=$2
	jar_name=$3
	back_api=$4
	if [ -f "$no_api/$jar_name" ];then
			read -p "$no_api/$jar_name文件已存在，是否重新替换文件 y/n：" jary
			if [ $jary = "y" ];then
				  if [ $back_api = 1 ];then
					  	if [ ! -d "$dk_back" ];then
							mkdir -p $dk_back
						fi
				  	 starttime=`date +'%Y%m%d%H%M%S'`
					#备份api文件
				  	 cp $no_api/$jar_name  $dk_back/bifang_api_$starttime.jar
				  fi
				rm -rf $no_api/$jar_name
				unzip_jar $no_api $cp_path $jar_name
			fi
		else
			if [ -d "$cp_path" ];then
				cp -r  $cp_path/*  $no_api 
			else
				echo "[`date '+%Y-%m-%d %T'`] 解压bifang.zip压缩文件"
				unzip bifang.zip -d /home
				cp  -r $cp_path/*  $no_api 
			fi
		fi
}

#------------------------------------镜像文件安装-------------------------------------------------------
dockerInit(){
	update_cfg
docker_count=`ps -ef|grep docker|grep -v grep`
if [ $? -ne 0 ];then
	echo "[`date '+%Y-%m-%d %T'`] 启动docker服务"
	systemctl stop docker
	systemctl start docker
fi
#centos-bifang镜像文件
centos=`docker images|grep centos* ` 
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] 导入centos-bifang镜像文件"
	d_centos=`cd /home/docker/centos/ && docker load -i centos-bifang.tar`
fi
jdk=`docker images|grep jdk* ` 
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] 安装jdk镜像文件"
	d_jdk=`cd /home/docker/jdk && docker build -t jdk:1.8.0_73 .`
fi
nginx=`docker images|grep nginx* ` 
if [ $? -ne 0 ]
then
echo "[`date '+%Y-%m-%d %T'`] 安装nginx镜像文件" 
	d_nginx=`cd /home/docker/bifang/nginx/ && docker load -i nginx.tar`
fi
echo "[`date '+%Y-%m-%d %T'`] 安装并启动api服务"
	d_api=`cd /home/docker/bifang/api/ && ./deploy-api.sh deployImagesAndStartContainer`	
echo "[`date '+%Y-%m-%d %T'`] 安装并启动bifang-html镜像文件"
	d_ui=`cd /home/docker/bifang/bifang-html/ && ./deploy-bifangHtml.sh deployImagesAndStartContainer`
echo "[`date '+%Y-%m-%d %T'`] 安装并启动syncredis同步服务"
	d_syn=`cd /home/docker/bifang/syncredis/ && ./deploy-syncredis.sh deployImagesAndStartContainer`
echo "[`date '+%Y-%m-%d %T'`] 安装并启动mapping-subid-ip映射服务"
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
			read -p "ui界面文件已存在，是否重新替换文件 y/n：" htmly
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
	echo "[`date '+%Y-%m-%d %T'`] 检测api服务是否启动成功。。。"
	sleep 1m
	#TOKEN 获取接口URL
	TOKEN_URL="http://127.0.0.1/v1/user/login?username=admin&password=admin"
	TOKEN=$(curl -s -X POST $TOKEN_URL|grep 'token'|awk -F':' '{print $2}'|awk -F'"' '{print $2}')
	echo "user login,token:${TOKEN}"
	if [ -z "$TOKEN" ]; then
		echo "[`date '+%Y-%m-%d %T'`] api服务token获取失败"
		read -p "(注：api服务启动慢会获取token失败，可重新获取) 请确认是否重新获取token  y/n：" api_token
		if [ $api_token = "y" ];then 
			api_check
			else
				echo "请检测api服务日志后（log目录/home/ceiec/bifang/api/logs），重新执行脚本"
		fi
	else 
		echo "[`date '+%Y-%m-%d %T'`] api服务启动成功"
		cer_sql="select count(*)  as '' from pxy_profile_trusted_ca_cert"
		cert_count=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name -P$db_port -e "${cer_sql}"`
		if [ $cert_count -gt 5 ];then 
			category_init
		else
			cert_init
		fi 
	fi
}


#--------------------------------解压docker文件--------------------------------------
unzip_inIt(){
	echo "[`date '+%Y-%m-%d %T'`] 开始解压docker文件"
	unzip docker.zip -d /home
	if [ $? -eq 0 ]
	then
	echo "[`date '+%Y-%m-%d %T'`] 解压完成"
			unzip_jar $dk_api $u_api $api_n 0
			unzip_jar $dk_syn $u_syn $syn_n 0 
			unzip_jar $dk_suid $u_suid $suid_n 0
		#.sh文件添加执行权限
		find /home/docker/* -name "*.sh" -type f  -exec chmod 755 \{\} \;

		docker_start

		config
	else
	echo "[`date '+%Y-%m-%d %T'`] 解压失败"
	fi
}

#-------------------------------修改t_sys_cfg参数-------------------------------
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

#------------------------------证书初始化-----------------------------------
cert_init(){
#修改minio参数
echo "[`date '+%Y-%m-%d %T'`] 证书初始化"
	d_cert=`cd /home/docker/db_init && ./bifang_init.sh`
	#检查文件是否执行成功
	cert_falg=`grep -i "true" /home/ceiec/bifang/init.log|wc -l`
	if [ $cert_falg -gt 0 ];then		
		cert_f=`grep -i "false" /home/ceiec/bifang/init.log|wc -l`
		if [ $cert_f -gt 0 ];then
			echo "[`date '+%Y-%m-%d %T'`] minio参数 账号：$minio_accessKey 密码：$minio_secretKey url:$minio_url "
			echo "[`date '+%Y-%m-%d %T'`] 证书初始异常，请检查minio中$minio_bucketName桶是否创建，及读写权限添加"
			minio_err
		else
			echo "[`date '+%Y-%m-%d %T'`] 证书初始化执行完成"
			category_init
		fi	
	else 
		echo "[`date '+%Y-%m-%d %T'`] minio参数 账号：$minio_accessKey 密码：$minio_secretKey url:$minio_url "
		echo "证书初始异常，请检查minio中$minio_bucketName桶是否创建，及读写权限添加"
		 minio_err
	fi

}

minio_err(){
	echo "1、重新执行初始化证书"
	echo "2、跳过证书初始化、继续执行下一步操作"
	read -p "请输入以上数字执行操作：" mnum 
	rm -rf /home/ceiec/bifang/init.log
	if [ $mnum -eq "1" ];then 
		cert_init
	elif [ $mnum -eq "2" ];then
		category_init
	else 
	  echo "请按以下操作，重新输入"
		minio_err
	fi 
}

category_init(){
	fqdn_sql="select count(*)  as '' from tsg_obj_fqdn_cat"
	fqdns=`mysql -h127.0.0.1 -uroot -p$db_pwd  $db_name  -P$db_port -e "${fqdn_sql}"`
	if [ $fqdns -gt 5 ];then 
		echo  "脚本执行完成"
	else
		echo "[`date '+%Y-%m-%d %T'`] 分类服务初始化"
        echo "[`date '+%Y-%m-%d %T'`] 安装并启动category服务分类程序"
	    d_sync=`cd /home/docker/categoryinit && ./deploy-category.sh deployImagesAndStartContainer`
		echo "[`date '+%Y-%m-%d %T'`] 服务分类数据初始化中。。。"
		sleep 40s
		echo "脚本执行完成"
	fi
}

#---------------------------------创建数据库-------------------------------------------------
db_init(){
		db_care=`mysql -h127.0.0.1 -uroot -p$db_pwd  -P$db_port -e "use $db_name"`
		if [ $? -eq 0 ];then
			read -p  "数据库$db_name 已存在，是否重新创建覆盖此数据库 y/n："  dby
			if [ $dby = "y" ];then 
				echo "[`date '+%Y-%m-%d %T'`] 创建$db_name数据库"
				#创建数据库
				db_in=`cd /home/docker/db_init/ && ./create_db.sh`
				echo "$db_in"
				dockerInit
			else 
				dockerInit
			fi
		else
			echo "[`date '+%Y-%m-%d %T'`] 创建$db_name数据库"
			#创建数据库
			db_in=`cd /home/docker/db_init/ && ./create_db.sh`
			echo "$db_in"
			dockerInit
		fi
}

#-----------------------------------检查minio参数-----------------------------------------
m_check(){
	minurl=$(curl -X POST --header "Accept: */*" -H "Content-Type: application/json"  --data '{"id": 1,"jsonrpc": "2.0", "params": {"username": "'"$minio_accessKey"'", "password": "'"$minio_secretKey"'"},"method": "Web.Login" }' ''"$minio_url/minio/webrpc"'')
	result=$(echo $minurl|grep 'token'|awk -F'token":"' '{print $2}'|awk -F'",' '{print $1}')
	if [[ $result != "" ]];then
		echo  "[`date '+%Y-%m-%d %T'`] minio连接参数正常"
		update_file
	else 
		echo "[`date '+%Y-%m-%d %T'`] minio参数 账号：$minio_accessKey 密码：$minio_secretKey url:$minio_url "
		mess=$(echo $minurl|grep 'message'|awk -F'message":"' '{print $2}'|awk -F'",' '{print $1}')
		if [ -z "$mess" ]; then
			echo "[`date '+%Y-%m-%d %T'`] minio参数连接失败"
		else
			echo "[`date '+%Y-%m-%d %T'`] minio参数连接异常：$mess"
		fi
		read -p "请重新输入mino的账号 密码 url，输入数字1则跳过检测，继续执行后续步骤：" m_accessKey m_secretKey m_url
		if [ $m_accessKey = 1 ];then
			echo "[`date '+%Y-%m-%d %T'`] 跳过minio检测"
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
	if [ -z "$time_zone" ]; then
		time_zone=`timedatectl | grep Time |awk -F'zone: ' '{print $2}'|awk -F'(' '{print $1}'`
	fi
	if [ -z "$api_port" ]; then
		api_port=8080
	fi
	if [ -z "$db_port" ]; then
		db_port=3306
	fi
	if [ -z "$kafka_groupid" ]; then
		kafka_groupid=tsg-consumer-cert
	fi	
}

config(){
	dbmysql=0
	which "mysql" > /dev/null
	if [ $? -eq 0 ];then
	   m_check
		db_init
	else 
		echo "[`date '+%Y-%m-%d %T'`] 安装mysql客户端服务"
		rpm -ivh /home/docker/db_init/db-client/*.rpm --force --nodeps
		which "mysql" > /dev/null
		if [ $? -eq 0 ];then
			echo "[`date '+%Y-%m-%d %T'`] mysql客户端服务安装成功"
			m_check
			db_init
		else 
			echo "[`date '+%Y-%m-%d %T'`] mysql客户端服务离线安装失败"
			echo "[`date '+%Y-%m-%d %T'`] mysql客户端在线安装"
			yum install mysql  -y	
		which "mysql" > /dev/null
		if [ $? -eq 0 ];then
			echo "[`date '+%Y-%m-%d %T'`] mysql客户端服务安装成功"
			m_check
			db_init
		else 
			dbmysql=1
			echo "[`date '+%Y-%m-%d %T'`] mysql客户端服务在线安装失败，请手动安装mysql远程客户端后重试"
			fi
		fi
	fi
}


bifang_init_start(){
	redad_contans
	if [ -d "/home/docker" ];
	then
		read -p "[`date '+%Y-%m-%d %T'`] docker目录已存在，请确认是否删除后，重新解压文件 y/n ：" ziInit
		if [ $ziInit = "y" ];then
			rm -rf /home/docker 
			unzip_inIt
		else
		#.sh文件添加执行权限
		find /home/docker/* -name "*.sh" -type f  -exec chmod 755 \{\} \;
		unzip_jar $dk_api $u_api $api_n 0
		unzip_jar $dk_syn $u_syn $syn_n 0
		unzip_jar $dk_suid $u_suid $suid_n 0
		echo "[`date '+%Y-%m-%d %T'`] 开始检查环境配置"
		docker_start
		echo "[`date '+%Y-%m-%d %T'`] 开始检查bifang_init_param.conf配置文件参数"
			config
		fi
	else
		unzip_inIt
	fi
}

update_ui(){
	bf_nginx=/home/docker/bifang/bifang-html/nginx.conf
	if [ -f "$bf_nginx" ];then
		read -p "请输入ui界面访问api的服务地址，主访问IP地址 备用IP地址（可不填备用） ："  api_nginx back_nginx
			sed -i "s%server.*weight.*;%server $api_nginx weight=5;%g" $bf_nginx
			 if [ -n "$back_nginx" ]; then
				sed -i "s%server.*:.*backup;%server $back_nginx backup;%g" $bf_nginx
			fi
		sed -i 's/\r$//'  $bf_nginx
		echo "毕方api界面服务重启中"
		d_ui=`cd /home/docker/bifang/bifang-html/ && ./deploy-bifangHtml.sh deployImagesAndStartContainer`
		echo "毕方api界面服务启动成功"
	  else
		echo "请安装api服务后重试！"
	fi
}
update_api(){
	echo "1、更新api服务jar包（请将最新bifang-api.jar包放在 /home/bifang/api/）"
	echo "2、更新syn同步服务（请将最新syncConfigToRedis.jar包放在/home/bifang/syncredis/,如配置文件更新则放在此目录下的config目录里）"
	echo "3、更新ui界面文件（请将最新界面文件放在 /home/bifang/bifang-html/ 目录下）"
	read -p "请输入以上数字执行操作：" api_num
	if [ -d "$dk_api" ];then
		if [ $api_num = 1 ];then
			unzip_jar $dk_api $u_api $api_n 1
			echo "毕方api服务jar包更新完成"
			echo "毕方api服务重启中"
				d_api=`cd /home/docker/bifang/api/ && ./deploy-api.sh deployImagesAndStartContainer`
				sleep 2m
			echo "毕方api服务启动完毕"
		elif [ $api_num = 2 ];then
			unzip_jar $dk_syn $u_syn $syn_n 0
			echo "毕方sync同步服务jar包更新完成"
			echo "毕方sync同步服务重启中"
				d_api=`cd /home/docker/bifang/syncredis/ && ./deploy-syncredis.sh deployImagesAndStartContainer`
				sleep 1m
			echo "毕方sync同步服务启动完毕"
		elif [ $api_num = 3 ];then
			cp_html
			echo "毕方ui界面更新完成"
	     else 
			echo "退出操作！"
		fi
	else
		echo "请安装api服务后重试！"
	fi
}

deldocker(){
	echo "停止所有docker容器"
	docker stop $(docker ps -a -q)
	echo "删除所有停止的docker容器"
	docker rm -f $(docker ps -aq)
}

del_docker(){
	echo "1、删除<none>异常的docker镜像文件"
	echo "2、删除所有docker镜像文件"
	read -p "请输入以上数字操作：" dk_num
	if [ $dk_num = 1 ];then
		none=`docker images|grep none|wc -l`
		if [ $none -gt 0 ];then
			deldocker
			echo "删除所有tag标签是none的镜像"
			docker images|grep none|awk '{print $3 }'|xargs docker rmi
			echo "删除成功！请重新安装api服务"
			echo "-------------------------------操作目录---------------------------------------"
			bf_start
		else
			echo "不存在<none>异常的docker镜像文件"
		fi
	elif [ $dk_num = 2 ];then
			deldocker
			echo "删除所有docker镜像文件"
			docker rmi $(docker images -q)
			echo "删除成功！请重新安装api服务"
			echo "-------------------------------操作目录---------------------------------------"
			bf_start
	else
		del_docker
	fi
}

up_network(){
	echo "检测docker网络环境"
	docker_ipv=$( cat /usr/lib/sysctl.d/00-system.conf |grep net.ipv4.ip_forward=1|wc -l )
	if [ $docker_ipv = 0 ]
	  then 
		echo "net.ipv4.ip_forward=1" >> /usr/lib/sysctl.d/00-system.conf
		echo "重启network服务"
	   systemctl restart network 

	   which "docker" > /dev/null
			if [ $? -eq 0 ]
			then
				echo "重启docker服务"
				systemctl restart docker
				echo "执行完成！"
			else 
				echo "执行完成！"
			fi	
	   else 
		echo "检测完成！"
	fi
}

api_uninstall(){
	echo "清理中。。。"
	rm -rf /home/docker
	rm -rf /home/bifang
	rm -rf /home/ceiec/bifang
	cp -r /home/ceiec/mariadb  /home/ceiec/mariadb_back
	rm -rf /home/ceiec/mariadb
	rm -rf /home/ceiec/reids
	deldocker
	echo "删除所有docker镜像文件"
	docker rmi $(docker images -q)
	echo "删除成功！请重新安装api服务"
}

kill_port(){
	read -p "请输入要停止的端口号：" kport
	for i in `lsof -i tcp:$kport | awk '{print $2}' | grep -v 'PID'`;
	do kill -9 $i
	done
	echo "端口$kport已停止"
}

bf_start(){
	echo "1、安装部署api服务"
	echo "2、调整ui界面api访问地址"
	echo "3、更新api服务"
	echo "------------------------------常见问题处理--------------------------------------------"
	echo "a、删除docker镜像文件（存在<none>的镜像文件）"
	echo "b、网络禁用docker镜像安装异常 （IPv4 forwarding is disabled. Networking will not work.）"
	echo "c、docker 端口占用异常"
	echo "d、一键删除（删除解压后的docker、bifang目录及docker镜像文件）"
	echo "------------------------------------------------------------------------------"
	read -p "请输入以上数字执行操作：" db_num
	if [ $db_num = "1" ];then
		up_network
		bifang_init_start
	elif [ $db_num = "2" ];then
		update_ui  
	elif [ $db_num = "3" ];then
		echo "------------------------更新服务目录----------------------------"
		update_api
	elif [ $db_num = "a" ];then
		which "docker" > /dev/null
		if [ $? -eq 0 ]
		then
			del_docker
		else 
			echo "docker服务不存在，请先安装API服务"
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
			echo "docker服务不存在，请先安装API服务"
		fi
	  else 
	  echo "-------------------------------操作目录---------------------------------------"
	   bf_start
	fi
}
echo "-------------------------------操作目录---------------------------------------"
bf_start

