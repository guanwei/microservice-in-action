#!/bin/bash
set -e

[[ -z "$1" ]] && echo "Usage: Please Specify deployment file !!!" && exit 1

# 根据环境解析配置文件
echo "Parsing config file $1..."

# 使用CloudFormation或者其他机制创建基础设施
echo "Creating resources..."

# 在节点中获取Docker镜像
echo "Pulling docker image..."

# 在节点中运行Docker容器
echo "Running docker contianer..."