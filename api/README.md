api服务部署脚本说明 （注将docker.zip、bifang.zip、docker_init.sh、bifang_init_param.conf文件放同一目录下）

bifang.zip文件：存放相关程序jar包，如有最新程序jar包，需手动解压文件到/home目录下替换目录中相关jar包即可
bifang_init_param.conf文件：需手动配置相关参数后，执行脚本

1、首先调整bifang_init_param.conf参数配置文件 

2、如有最新程序jar包，需手动解压bifang.zip文件到/home目录下，替换目录中相关jar包即可
   解压后目录说明:
            （/home/bifang/api/  存放bifang-api.jar api服务jar包）
            （/home/bifang/syncredis/  存放syncConfigToRedis.jar 同步服务jar包）
            （/home/bifang/webfocus/  存mapping-subid-ip.jar IP映射服务jar包）
            （/home/bifang/bifang-html/  api界面ui部署文件）
            
3、执行docker_init.sh脚本文件