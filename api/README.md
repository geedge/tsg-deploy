api服务部署脚本说明 （注将docker.zip、docker_init.sh、bifang_init_param.conf文件放同一目录下）

1、调整bifang_init_param.conf参数配置文件 

2、手动解压docker.zip文件到/home目录

3、把api服务bifang_api.jar 放在/home/docker/bifang/api目录下

3、把同步程序syncConfigToRedis.jar 放在/home/docker/bifang/syncredis目录下

4、执行docker_init.sh脚本文件

5、执行完毕后，将界面UI部署文件放置在/home/ceiec/bifang/ui/bifang-html 目录下，访问即可