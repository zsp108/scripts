#!/bin/bash

env_sudo() {
  echo ${LINUX_PASSWORD} | sudo -S $1
}

#修改$HOME/.bashrc文件
init_bash(){
    cp $HOME/.bashrc $HOME/.bashrc_bak
    tee -i $HOME/.bashrc << EOF
# User specific aliases and functions
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'


# User specific environment
# Basic envs
export LANG="en_US.UTF-8" # 设置系统语言为 en_US.UTF-8，避免终端出现中文乱码
export PS1='[\u@dev \W]\$ ' # 默认的 PS1 设置会展示全部的路径，为了防止过长，这里只展示："用户名@dev 最后的目录名"
export WORKSPACE="$HOME/workspace" # 设置工作目录
export PATH=$HOME/bin:$PATH # 将 $HOME/bin 目录加入到 PATH 变量中
 
# Default entry folder
cd $WORKSPACE # 登录系统，默认进入 workspace 目录
EOF
    #创建工作路径
    mkdir -p /data/zsp/workspace 
    ln -s /data/zsp/workspace $HOME/workspace
}

install_lib(){
    if [[ $OSNAME=='debian' ]];then
        env_sudo "apt-get update -y"
        env_sudo "apt-get -y install make autoconf automake cmake libtool gcc zlib1g-dev tcl-dev git-lfs telnet ctags lrzsz jq openssl expat dh-autoreconf libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev libghc-zlib-dev libprotoc-dev"
    elif [[ $OSNAME=='redhat' ]];then
        env_sudo "yum update -y"
        env_sudo "yum -y install make autoconf automake cmake perl-CPAN libcurl-devel libtool gcc gcc-c++ glibc-headers zlib-devel git-lfs telnet ctags lrzsz jq expat-devel openssl-devel"
    fi
}

os_tpye(){
    declare -g OSNAME
    if [[ -f /etc/redhat-release ]];then
        OSNAME='redhat'
    elif [[ -f /etc/lsb-release ]];then
        OSNAME='debian'
    fi
    # echo "$OSNAME"
        
}

if [[ ! "$*" ]];then
    os_tpye
    echo "$OSNAME"
    # init_bash
    install_lib
fi
