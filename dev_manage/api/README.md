api服务部署脚本说明
1、手动解压docker.zip文件到/home目录

2、把api服务bifang_api.jar 放在/home/docker/bifang/api目录下

3、把同步程序syncConfigToRedis.jar 放在/home/docker/bifang/syncredis目录下

4、调整/home/docker/bifang/api/config/application-dev.properties 配置文件中数据库和redis连接参数

5、调整/home/docker/bifang/syncredis/config/application.properties 配置文件中数据库和redis连接参数

6、调整/home/docker/bifang/webfocus/config/application.properties 配置文件中数据库和redis连接参数

7、运行docker_init.sh脚本文件，执行完成后，修改数据库t_sys_cfg表中minio_url连接地址

8、在/home/docker/bifang/api 目录下执行./deploy-api.sh deployImagesAndStartContainer 重新启动服务

9、执行db_init.sh脚本文件，初始化证书及分类服务数据
