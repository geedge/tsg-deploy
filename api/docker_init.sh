#!/bin/bash
#-------------------------------------------------------
CUR_PRGDIR=`pwd` #当前文件的路径
#读取配置文件
PROP_FILE="$CUR_PRGDIR/bifang_init_param.conf"
prop_value=""
#------------------------------------------------------------------------------functions
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
		prop_value=`echo ${temp#*=}| sed 's/^[ \t]*|[ \t]*$//g'|sed 's/\r//'`
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
read_file "db_host" "y"
db_host="$prop_value"
read_file "db_user" "y"
db_user="$prop_value"
read_file "db_pwd" "y"
db_pwd="$prop_value"
read_file "db_name" "y"
db_name="$prop_value"
#-----------------------------------------------------
read_file "api_reids_host" "y"
api_reids_host="$prop_value"
read_file "api_redis_port" "y"
api_redis_port="$prop_value"
#--------------------------------------------
read_file "syn_redis_host" "y"
syn_redis_host="$prop_value"
read_file "syn_redis_port" "y"
syn_redis_port="$prop_value"
#--------------------------------------------------
read_file "minio_url" "y"
minio_url="$prop_value"
read_file "minio_accessKey" "y"
minio_accessKey="$prop_value"
read_file "minio_secretKey" "y"
minio_secretKey="$prop_value"
read_file "minio_bucketName" "y"
minio_bucketName="$prop_value"
read_file "api_ip" "y"
api_ip="$prop_value"
read_file "api_port" "y"
api_port="$prop_value"
#-----------------------------------------------------------------------------------------
update_file(){
#--------------------------------修改相关文件参数---------------------------------------------------------
api_config=/home/docker/bifang/api/config/application-dev.properties
syn_config=/home/docker/bifang/syncredis/config/application.properties
webfocus_config=/home/docker/bifang/webfocus/config/application.properties
fqdn_config=/home/docker/categoryinit/config.properties
api_port_config=/home/docker/bifang/api/config/application.properties
#---------------------------------修改api配置文件------------------------
`sed -i "s%spring.datasource.url=.*%spring.datasource.url=jdbc:mysql://$db_host:3306/$db_name?rewriteBatchedStatements=true%g" $api_config` 
`sed -i "s%spring.datasource.username=.*%spring.datasource.username=$db_user%g" $api_config` 
`sed -i "s%spring.datasource.password=.*%spring.datasource.password=$db_pwd%g" $api_config` 

`sed -i "s%spring.redis.host=.*%spring.redis.host=$api_reids_host%g" $api_config` 
`sed -i "s%spring.redis.port=.*%spring.redis.port=$api_redis_port%g" $api_config` 

`sed -i "s%server.port=.*%server.port=$api_port%g" $api_port_config` 
#----------------------------------修改syn同步服务配置文件----------------------------------------------------------------------
`sed -i "s%spring.datasource.url=.*%spring.datasource.url=jdbc:mysql://$db_host:3306/$db_name?rewriteBatchedStatements=true%g" $syn_config` 
`sed -i "s%spring.datasource.username=.*%spring.datasource.username=$db_user%g" $syn_config` 
`sed -i "s%spring.datasource.password=.*%spring.datasource.password=$db_pwd%g" $syn_config` 

`sed -i "s%spring.redis.host=.*%spring.redis.host=$syn_redis_host%g" $syn_config` 
`sed -i "s%spring.redis.port=.*%spring.redis.port=$syn_redis_port%g" $syn_config` 
#-----------------------------------修改映射服务配置文件---------------------------------------------------------------------------------------------
`sed -i "s%spring.datasource.url=.*%spring.datasource.url=jdbc:mysql://$db_host:3306/$db_name?rewriteBatchedStatements=true%g" $webfocus_config` 
`sed -i "s%spring.datasource.username=.*%spring.datasource.username=$db_user%g" $webfocus_config` 
`sed -i "s%spring.datasource.password=.*%spring.datasource.password=$db_pwd%g" $webfocus_config` 
`sed -i "s%spring.redis.host=.*%spring.redis.host=$syn_redis_host%g" $webfocus_config` 
`sed -i "s%spring.redis.port=.*%spring.redis.port=$syn_redis_port%g" $webfocus_config` 
#------------------------------------修改服务分类配置文件--------------------------------------------------------------------------------------------------------------
`sed -i "s%url=.*true%url=jdbc:mysql://$db_host:3306/$db_name?rewriteBatchedStatements=true%g" $fqdn_config` 
`sed -i "s%username=.*%username=$db_user%g" $fqdn_config` 
`sed -i "s%password=.*%password=$db_pwd%g" $fqdn_config`
#-------------------------------------修改脚本配置参数---------------------------------------------------------------------------------------------------
#证书脚本参数修改
bifang_init=/home/docker/db_init/bifang_init.sh
#数据库创建脚本修改
create_db=/home/docker/db_init/create_db.sh
`sed -i "s%CACERT_URL=.*%CACERT_URL='http://$api_ip:$api_port/v1/policy/profile/trustedcacertobj'%g" $bifang_init` 
`sed -i "s%KEYRING_URL=.*%KEYRING_URL='http://$api_ip:$api_port/v1/policy/profile/keyringobj'%g" $bifang_init` 
`sed -i "s%TOKEN_URL=.*/v1%TOKEN_URL='http://$api_ip:$api_port/v1%g" $bifang_init` 

`sed -i "s%DB_HOST=.*%DB_HOST=$db_host%g" $bifang_init` 
`sed -i "s%DB_USER=.*%DB_USER=$db_user%g" $bifang_init` 
`sed -i "s%DB_PWD=.*%DB_PWD=$db_pwd%g" $bifang_init` 
`sed -i "s%DB_NAME=.*%DB_NAME=$db_name%g" $bifang_init` 
#初始化数据库脚本修改
`sed -i "s%DB_HOST=.*%DB_HOST=$db_host%g" $create_db` 
`sed -i "s%DB_USER=.*%DB_USER=$db_user%g" $create_db` 
`sed -i "s%DB_PWD=.*%DB_PWD=$db_pwd%g" $create_db` 
`sed -i "s%DB_NAME=.*%DB_NAME=$db_name%g" $create_db`

`sed -i 's/\r$//'  $create_db`
`sed -i 's/\r$//'  $bifang_init`
`sed -i 's/\r$//'  $fqdn_config`
`sed -i 's/\r$//'  $webfocus_config`
`sed -i 's/\r$//'  $syn_config`
`sed -i 's/\r$//'  $api_config`
`sed -i 's/\r$//'  $api_port_config`
}	
#----------------------------------------------------------
docker_start () {
#判断docker是否安装
which "docker" > /dev/null
if [ $? -eq 0 ]
then
  echo "docker已存在,开始安装镜像文件"
	dockerInit
else
#执行脚本文件安装docker
  echo "开始安装docker"
  dockerPath=/home/docker/docker_init/docker-deploy.sh
	 `cd /home/docker/docker_init/ && ./docker-deploy.sh`

   which "docker" > /dev/null
	if [ $? -eq 0 ]
	then
		echo "docker安装成功"
		echo "开始安装docker镜像文件。。。"
		dockerInit
	fi
fi
}

dockerInit(){

docker_count=`ps -ef|grep docker|egrep -v grep`
if [ $? -ne 0 ];then
	echo "启动docker服务"
	`systemctl stop docker`
	`systemctl start docker`
fi

#centos-bifang镜像文件
centos=`docker images|grep centos* ` 
if [ $? -ne 0 ]
then
echo "导入centos-bifang镜像文件"
	`cd /home/docker/centos/ && docker load -i centos-bifang.tar`
fi

jdk=`docker images|grep jdk* ` 
if [ $? -ne 0 ]
then
echo "安装jdk镜像文件"
	`cd /home/docker/jdk && docker build -t jdk:1.8.0_73 .`
fi

nginx=`docker images|grep nginx* ` 
if [ $? -ne 0 ]
then
echo "安装nginx镜像文件" 
	`cd /home/docker/bifang/nginx/ && docker load -i nginx.tar`
fi	
echo "安装并启动bifang-html镜像文件"
	`cd /home/docker/bifang/bifang-html/ && ./deploy-bifangHtml.sh deployImagesAndStartContainer`
echo "安装并启动api服务"
	`cd /home/docker/bifang/api/ && ./deploy-api.sh deployImagesAndStartContainer`
echo "安装并启动syncredis同步服务"
	`cd /home/docker/bifang/syncredis/ && ./deploy-syncredis.sh deployImagesAndStartContainer`
echo "安装并启动mapping-subid-ip映射服务"
	`cd /home/docker/bifang/webfocus/ && ./deploy-webfocus.sh deployImagesAndStartContainer`
	category_init
}

unzip_inIt(){
	echo "开始解压"
	unzip docker.zip -d /home
	if [ $? -eq 0 ]
	then
	echo "解压完成"
		#.sh文件添加执行权限
		`find /home/docker/* -name "*.sh" -type f  -exec chmod 755 \{\} \;`
		config
	else
	echo "解压失败"
	fi
}

update_minio(){
	murl="update t_sys_cfg  set cfg_value='$minio_url' where cfg_name='minio_url';update t_sys_cfg  set cfg_value='$minio_accessKey' where cfg_name='minio_accessKey';update t_sys_cfg  set cfg_value='$minio_secretKey' where cfg_name='minio_secretKey';update t_sys_cfg  set cfg_value='$minio_bucketName' where cfg_name='minio_bucketName'"
	db_m=`mysql -h$db_host -u$db_user -p$db_pwd  $db_name -e "${murl}"`
}


category_init(){
	update_minio
	echo "证书初始化"
	`cd /home/docker/db_init && ./bifang_init.sh`
	echo "证书初始化执行完成"
	echo "分类服务初始化"
	`cd /home/docker/categoryinit && java -jar categoryInit.jar`
	echo "脚本执行完成"
}


db_init(){
	dbnoit=`mysql -h$db_host -u$db_user -p$db_pwd -e 'use mysql'`
	if [ $? -eq 0 ];then
		db_care=`mysql -h$db_host -u$db_user -p$db_pwd -e "use $db_name"`
		if [ $? -eq 0 ];then
			docker_start
		else
			echo "创建$db_name数据库"
			#创建数据库
			db_in=`cd /home/docker/db_init/ && ./create_db.sh`
			echo "$db_in"
			docker_start
		fi
	else
		echo "请调整bifang_init_param.conf数据库参数配置"
	fi

}

config(){
	echo "开始检查bifang_init_param.conf配置文件参数"
	update_file
	if [ $? -eq 0 ];then
		echo "配置参数调整完成"
		db_init
	else
		echo "请调整bifang_init_param.conf数据库参数配置"
	fi
}

if [ -d "/home/docker" ];
	then
		read -t 30 -n 1 -p "docker目录已存在，请确认是否删除后，重新解压文件 y/n ：" ziInit
		echo -e "\n"
		if [ $ziInit = "y" ];then
			`rm -rf /home/docker`
			unzip_inIt
		else
		#.sh文件添加执行权限
		`find /home/docker/* -name "*.sh" -type f  -exec chmod 755 \{\} \;`
			config
		fi
	else
		unzip_inIt
	fi
