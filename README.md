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

# 安装方法

* 使用 NodeJS 自带的包管理器 npm 来安装该程序：`npm install lixian-portal -g`
* 运行命令启动：`lixian-portal`
* 下载的位置为启动这个程序的目录(Current Working Directory)
* 如需下载到其他位置，可以设置环境变量`LIXIAN_PORTAL_HOME`，例如：可以这样启动程序`LIXIAN_PORTAL_HOME=/mnt/sdb1 lixian-portal`

# Tricks

* 如果想让它一直在后运行，可以使用这个命令启动`nohup lixian-portal &`

# 感谢

这个程序的核心逻辑主要参考了 [@iambus](https://github.com/iambus) 的作品 [xunlei-lixian](https://github.com/iambus/xunlei-lixian)，没有他完成的分析迅雷API的工作，这个程序不可能这么容易地实现，在此向他表示感谢。

# 代码授权协议

The MIT License (MIT)

Copyright (c) 2013 Michael Yin

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

