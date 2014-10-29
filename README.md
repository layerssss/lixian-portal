lixian-portal
=============

一个简洁实用的 Web 版迅雷离线下载程序。注：迅雷离线下载是仅为迅雷会员提供的服务，未开通会员的迅雷账户可能无法登录。

# 这是啥

我也不知道这是啥，见下一章说明吧

# 典型使用场景

1. 家里有个 HTPC，运行着这个程序
2. 我平常刷微博时发现先几个好看的电影，和想玩的游戏，然后再xxx上找到这些电影和游戏的ed2k链接，然后输入进去
3. 周末我通过 samba 文件共享打开这个程序已经下好的电影和游戏，看之且玩之
4. 室友也可以看（如果有室友的话）

# 界面预览

![qq20140929-1](https://cloud.githubusercontent.com/assets/1559832/4437710/10a2f2d4-479e-11e4-888f-eae2f34b5bff.png)

![qq20140929-2](https://cloud.githubusercontent.com/assets/1559832/4437711/1110e618-479e-11e4-8885-b28024c6864d.png)


# 环境

* [NodeJS](http://nodejs.org/)
* [PhantomJS](http://phantomjs.org/)

# 安装方法

* 使用 NodeJS 自带的包管理器 npm 来安装该程序：`npm install lixian-portal -g`
* 运行命令启动：`lixian-portal`
* 下载的位置为启动这个程序的目录(Current Working Directory)
* 如需下载到其他位置，可以设置环境变量`LIXIAN_PORTAL_HOME`，例如：可以这样启动程序`LIXIAN_PORTAL_HOME=/mnt/sdb1 lixian-portal`

# Tricks

* 如果想让它一直在后运行，可以使用这个命令启动`nohup lixian-portal &`
