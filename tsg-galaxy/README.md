# 大数据组件基于Docker模式的单机部署文档

> 因docker镜像都比较大，固需要在信息港环境提前拷贝一份环境文件到需要的机器上，整体大约 7.5G。

## 安装前提：

    1：服务器机器关闭防火墙
    2：服务器安装JDK，版本：1.8.0_73
    3：编辑服务器上 /etc/selinux/config 把其中的SELINUX=enforce改成disabled

## 提供自动安装脚本，操作步骤：

    1.登录信息港环境 192.168.40.153 服务器，将 /home/bigdata/docker/Tsg_Galaxy_v2.0.20190630 文件夹整体移动到要部署的服务器上。

    2.打开setup_all.sh按照模板和提示修改内容。
        (1)注意DRUID_TIMEZONE配置的格式，因sed命令的原因，/ 会引起问题，固只修改 Asia 和 Almaty 中间勿动
        
    3.因报表和Druid都需要使用Mariadb目前与页面使用同一个数据库，需要修改报表使用的数据库名和创建Druid数据库；方法如下：
        (1)在Mariadb所在机器使用命令进入mysql -u root -p  (如用户名不是root自行修改)
        
        (2)进入后使用命令：create database druid DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

    4.配置修改，druid数据库创建完成后，执行setup_all.sh 脚本等待过后即完成安装。


## 简单的命令

- ### 查看容器ID
        使用命令 docker ps 查看要重启容器的ID即 CONTAINER ID 下的一个字符

- ### 重启docker容器
        后使用命令 docker restart 要重启容器的ID

- ### 进入容器
        docker exec -it 要进入容器的ID /bin/bash

## UI界面

    浏览器登录 服务器IP:5050 进入容器管理界面