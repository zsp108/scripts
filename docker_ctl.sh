#!/bin/bash


image_name=stonedb

function docker_sudo(){
    echo "$LINUX_PASSWORD" | sudo -S $1
}

function docker_build(){

    # cur_tag=`docker images | grep "$image_name"|awk '{print $2}'|head -n 1`
    cur_tag=`docker_sudo "docker images | grep "$image_name"|awk '{print $2}' |awk 'BEGIN{ max = 0} {if ($1 > max) max = $1; fi} END{printf "%d\n",max}'"`
    if [ $cur_tag ];then
        tag=$[$cur_tag+1]
    else
        tag=1
    fi
    echo "`date ` : docker build --rm -t $image_name:$tag ."
    docker_sudo "docker build --rm -t $image_name:$tag ." #> /dev/null

    echo "docker run -p 13306:3306 -v /data/zsp/workspace/dockerdata/data:/stonedb56/install/data/ -it $image_name:$tag /bin/bash"
    # echo "docker exec -it $image_name:$tag bash"
}

function docker_rm(){
    docker_sudo "docker rm `docker ps -a|grep Exited|awk '{print $1}'`"
}

# function docker_rmi(){
#     docker rmi `docker images -a|grep stonedb|awk '{print $1}'`
# }

if [ ! "$*" ];then
    docker_build
else
    eval $*
fi
