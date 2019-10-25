#!/bin/bash

#数据库连接参数
DB_HOST=192.168.142.134
DB_USER=root
DB_PWD=111111
DB_NAME=tsg_bifang
SQL_FILE=/home/docker/db_init/tsg-bifang.sql


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
}


echo "开始创建数据库"
mysql -h $DB_HOST -u $DB_USER -p$DB_PWD -e "create database IF NOT EXISTS ${DB_NAME} default character set = 'utf8mb4'";
echo "create DB"
mysql -h $DB_HOST -u $DB_USER -p$DB_PWD -f $DB_NAME -e "source $SQL_FILE";
echo "create table and view"


	dbnoit=`mysql -u$DB_USER -p$DB_PWD -e "use $DB_NAME" `
	if [ $? -eq 0 ];then
		docker_start
	else
		echo "创建tsg_bifang数据库失败，请调整脚本信息"
		
	fi






