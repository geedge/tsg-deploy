#!/bin/bash
category_init(){
	echo "分类服务初始化"
	`cd /home/docker/categoryinit && java -jar categoryInit.jar`
}
	echo "证书初始化"
	`cd /home/docker/db_init && ./bifang_init.sh`
	category_init
	echo "脚本执行完成"


