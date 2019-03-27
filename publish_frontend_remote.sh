#!/bin/bash
# Author: BarryNg
# Date: 2019-01-08
# Description: 前端远程自动发布脚本（配合Jenkins使用）
# 提醒：使用该脚本前先配置好目标服务器的免密登录。

# 步骤说明：
# 1、编译
# 2、备份当前程序
# 3、复制打包好的程序到对应目录（远程）


# 参数说明：
# 1、BUILD_PATH：jenkins打包完的程序目录(/root/.jenkins/workspace/jenkins项目名称之后的路径)，例：BUILD_PATH="dist"
# 2、TARGET_PATH：应用部署目录，例：TARGET_PATH="/data/wwwroot"
# 3、TARGET_DIR：项目名称(解压目录名称，目标服务器目录名)，例：TARGET_DIR="schoolhonor-iview"
# 4、SSH_USER：远程主机登录用户
# 5、SSH_HOST：远程主机IP
# 6、SSH_PORT：远程主机登录端口
# eg: /tool/shellscript/schoolhonor_frontend_remote.sh dist /data/wwwroot schoolhonor-iview root 192.168.0.115 22

BUILD_PATH="$1"
TARGET_PATH="$2"
TARGET_DIR="$3"
SSH_USER="$4"
SSH_HOST="$5"
SSH_PORT="$6"

function build(){
	cd $WORKSPACE;
	#node -v
	#npm -v
	#npm install chromedriver --chromedriver_cdnurl=http://cdn.npm.taobao.org/dist/chromedriver
	npm install
	npm run build;
}

function backup(){
	ssh -p $SSH_PORT ${SSH_USER}@${SSH_HOST} "cd $TARGET_PATH;tar -czf $TARGET_DIR-$(date +%s).tar.gz $TARGET_DIR/*;"
	if [ $? -ne 0 ];then
		echo -e "\n\e[1;31mERROR:程序备份失败\e[0m"
	    exit 10;
	else
		echo -e "\n\e[1;34mINFO:程序备份成功\e[0m"
	fi
}

function deploy_rsync(){
	echo $WORKSPACE/$BUILD_PATH
	if ( [ -n "$BUILD_PATH" ] && [ -e  $WORKSPACE/$BUILD_PATH ] )
	then
		# 删除目录，创建目录，复制项目
		rm -rf $WORKSPACE/$TARGET_DIR;
		mkdir $WORKSPACE/$TARGET_DIR;
		mv $WORKSPACE/$BUILD_PATH/* $WORKSPACE/$TARGET_DIR;
		rsync -azP --delete -e "ssh -p $SSH_PORT" $WORKSPACE/$TARGET_DIR $SSH_USER@$SSH_HOST:$TARGET_PATH >/dev/null
		if [ $? -ne 0 ]
        then
        	echo -e "\n\e[1;31mERROR:未成功部署，请检查是否已添加该服务器到 ${SSH_USER}@${SSH_HOST} 的免密登录。\e[0m"
            exit 10
        else
        	echo -e "\n\e[1;34mINFO:打包文件复制成功\e[0m"
        fi
	else
		echo -e "\n\e[1;31mERROR:打包文件不存在\e[0m"
		exit 10
	fi
}

# main
if ([ -z "$BUILD_PATH" ] || [ -z "$TARGET_PATH" ] || [ -z "TARGET_DIR" ] || [ -z "SSH_USER" ] || [ -z "SSH_HOST" ] || [ -z "SSH_PORT" ] )
then
        echo -e "\n\e[1;31mERROR:参数检查失败, 以下为必要参数：\e[0m"
        echo -e "BUILD_PATH\t-\t$BUILD_PATH"
        echo -e "TARGET_PATH\t-\t$TARGET_PATH"
        echo -e "TARGET_DIR\t-\t$TARGET_DIR"
        echo -e "SSH_USER\t-\t$SSH_USER"
        echo -e "SSH_HOST\t-\t$SSH_HOST"
        echo -e "SSH_PORT\t-\t$SSH_PORT"
        exit 10
fi

build
backup
deploy_rsync