#!/bin/bash

function env::log:porint(){
    local type="$1"
    local dt; dt="$(date --rfc-3339=seconds)"
    local text="$*"; if [ "$#" -eq 0 ]; then text="$(cat)"; fi
    printf '%s [%s]: %s\n' "$dt" "$type" "$text"
}
function env::log::info(){
    env::log:porint Info "$@"
}
function env::log::warn(){
    env::log:porint Warning "$@" >&2
}
function env::log::error(){
    env::log:porint Error "$@" >&2
    # exit 1
}


#获取sudo 权限，
function env::sudo() {
  echo ${LINUX_PASSWORD} | sudo -S $1
}

#判断操作系统类型
function env::get::ostype() {
    declare -g OSNAME
    if [[ -f /etc/redhat-release ]];then
        OSNAME='redhat'
    elif [[ -f /etc/lsb-release ]];then
        OSNAME='debian'
    fi
    # echo "$OSNAME"
}

#修改$HOME/.bashrc文件
function env::init::bashrc() {
	if [ -f $HOME/.bashrc_bak ];then
		rm $HOME/.bashrc
        env::log::warn "rm $HOME/.bashrc"
	else
		cp $HOME/.bashrc $HOME/.bashrc_bak
        env::log::warn "cp $HOME/.bashrc $HOME/.bashrc_bak"
	fi

cat << 'EOF' > $HOME/.bashrc

# User specific aliases and functions
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

if [ -f ~/.git-completion.bash ]; then
        . ~/.git-completion.bash
fi

# User specific environment
# Basic envs
export LANG="en_US.UTF-8" # 设置系统语言为 en_US.UTF-8，避免终端出现中文乱码
export PS1='[\u@dev \W]\$ ' # 默认的 PS1 设置会展示全部的路径，为了防止过长，这里只展示："用户名@dev 最后的目录名"
export WORKSPACE="$HOME/workspace" # 设置工作目录
export PATH=$HOME/bin:$PATH # 将 $HOME/bin 目录加入到 PATH 变量中

# Default entry folder
cd $WORKSPACE # 登录系统，默认进入 workspace 目录

alias ws="cd $WORKSPACE"
EOF

    #创建工作路径
    if [ ! -d $HOME/workspace ];then
        mkdir -p /data/zsp/workspace 
        ln -s /data/zsp/workspace $HOME/workspace
    fi
    source $HOME/.bashrc
    env::log::info "prepare linux successfully"
}

# Go环境搭建依赖安装
function env::install::lib() {
    if [[ $OSNAME=='debian' ]];then
        env::sudo "apt-get update -y"
        env::sudo "apt-get -y install make autoconf automake cmake libtool gcc zlib1g-dev tcl-dev git-lfs telnet ctags lrzsz jq openssl expat dh-autoreconf libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev libghc-zlib-dev libprotoc-dev"
    elif [[ $OSNAME=='redhat' ]];then
        env::sudo "yum update -y"
        env::sudo "yum -y install make autoconf automake cmake perl-CPAN libcurl-devel libtool gcc gcc-c++ glibc-headers zlib-devel git-lfs telnet ctags lrzsz jq expat-devel openssl-devel"
    fi
}

#git 安装
function env::install::git(){
    rm -rf /tmp/git-2.36.1.tar.gz /tmp/git-2.36.1 # clean up
  cd /tmp
  wget --no-check-certificate https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.36.1.tar.gz
  tar -xvzf git-2.36.1.tar.gz
  cd git-2.36.1/
  ./configure
  make
  env::sudo "make install"
  env::sudo "cp /tmp/git-2.36.1/contrib/completion/git-completion.bash $HOME/.git-completion.bash"

  cat << 'EOF' >> $HOME/.bashrc
# Configure for git
export PATH=/usr/local/libexec/git-core:$PATH
EOF

  git --version | grep -q 'git version 2.36.1' || {
    env::log::error "git version is not '2.36.1', maynot install git properly"
    return 1
  }

  # 5. 配置 Git
  git config --global user.name "SP Zhang"    # 用户名改成自己的
  git config --global user.email "echo996@foxmail.com"    # 邮箱改成自己的
  git config --global credential.helper store    # 设置 Git，保存用户名和密码
  git config --global core.longpaths true # 解决 Git 中 'Filename too long' 的错误
  git config --global core.quotepath off
  git lfs install --skip-repo

  source $HOME/.bashrc
  env::log::info "Install git successfully"
}

#go 安装 复制 iam 项目脚本：https://github.com/marmotedu/iam/blob/master/scripts/install/install.sh
function env::install::go(){
    rm -rf /tmp/go1.18.3.linux-amd64.tar.gz $HOME/go/go1.18.3 # clean up

  # 下载 go1.18.3 版本的 Go 安装包
  wget -P /tmp/ https://golang.google.cn/dl/go1.18.3.linux-amd64.tar.gz

  # 安装 Go
  mkdir -p $HOME/go
  tar -xvzf /tmp/go1.18.3.linux-amd64.tar.gz -C $HOME/go
  mv $HOME/go/go $HOME/go/go1.18.3

  # 配置 Go 环境变量
  cat << 'EOF' >> $HOME/.bashrc
# Go envs
export GOVERSION=go1.18.3 # Go 版本设置
export GO_INSTALL_DIR=$HOME/go # Go 安装目录
export GOROOT=$GO_INSTALL_DIR/$GOVERSION # GOROOT 设置
export GOPATH=$WORKSPACE/golang # GOPATH 设置
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH # 将 Go 语言自带的和通过 go install 安装的二进制文件加入到 PATH 路径中
export GO111MODULE="on" # 开启 Go moudles 特性
export GOPROXY=https://goproxy.cn,direct # 安装 Go 模块时，代理服务器设置
export GOPRIVATE=
export GOSUMDB=off # 关闭校验 Go 依赖包的哈希值
EOF
  source $HOME/.bashrc

  # 初始化 Go 工作区
  mkdir -p $GOPATH && cd $GOPATH
  go work init
  env::log::info "Install Golang successfully"
}
#



env::get::ostype
echo "This OS is $OSNAME"

if [[ ! "$*" ]];then
    #$HOME/.bashrc 配置文件修改
    env::init::bashrc
    #安装所需要的依赖
    # env::install::lib
    #安装Git
    # env::install::git
    #安装Go语言环境
    # env::install::go

fi
