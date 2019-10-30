## 注意事项
1.  TSG系统部署分为：功能端、设备管理、UI+API、大数据、公共组件及部分；
2.  各部分研发将部署文档及安装文件链接及时上传到本项目中，方便运维同事部署/升级新环境；
3.  新环境部署顺序：a、硬件设备、网络环境；b、时钟同步；c、公共组件；d、自研程序

## ADC软件部署方案  
| mxn | mcn0 | mcn1 | mcn2 | mcn3 |
| --- | ---- | ---- | ---- | :---- | 
| | sapp | tfe | tfe| tfe |
| | certstore | | | |
| consul-external| consul-internal | consul-internal | consul-internal | consul-internal |
| oam_core | tsgcli | tsgcli | tsgcli | tsgcli |
| oam_snmp | tsg_monitor | tsg_monitor | tsg_monitor | tsg_monitor |
| oam_cli_agent_mxn | oam_cli_agent | oam_cli_agent | oam_cli_agent | oam_cli_agent | 
