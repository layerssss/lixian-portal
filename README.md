lixian-portal
=============

给`iambus/xunlei-lixian`做的一个简洁实用的webui。（不明真相的同学赶快先去膜拜了[iambus/xunlei-lixian](https://github.com/iambus/xunlei-lixian)了再回来）

# 这是啥

我也不知道这是啥，见下一章说明吧

# 典型使用场景

1. 家里有个连着移动硬盘的树莓派
2. 我平常刷微博时发现先几个好看的电影，和想玩的游戏，然后再xxx上找到这些电影和游戏的ed2k链接，然后输入进去
3. 周末我通过smb文件共享打开树莓派里已经下好的电影和游戏，看之且玩之
4. 室友也可以看（如果有室友的话）

# 界面预览

![http://ww3.sinaimg.cn/large/7a464815jw1e5klmtnyu6j20zk0m8my3.jpg](http://ww3.sinaimg.cn/large/7a464815jw1e5klmtnyu6j20zk0m8my3.jpg)

![http://ww3.sinaimg.cn/large/7a464815jw1e5kln13fotj20zk0m8myv.jpg](http://ww3.sinaimg.cn/large/7a464815jw1e5kln13fotj20zk0m8myv.jpg)

# 环境

* linux/osx （如果你想用windows来做下载服务器，你得先在windows上安装好wget）
* python2
* nodejs

# 安装方法

* 下载代码并解压缩
* 运行命令启动`node /path/to/lixian-portal` 
* 下载的位置为启动这个程序的目录(Current Working Directory)
* 如需下载到其他位置，可以设置环境变量`LIXIAN_PORTAL_HOME`，例如：可以这样启动程序`LIXIAN_PORTAL_HOME=/mnt/sdb1 node /path/to/lixan-portal`

# Tricks

* 如果想让它一直在后运行，可以使用这个命令启动`nohup node /path/to/lixian-portal &`
* `lixian-portal`兼容`xunlei-lixian`的设置，按这样的命令格式设置即可`HOME=/path/to/lixian-portal/Downloads lx config output-dir /mnt/Downloads`
