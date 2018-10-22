#!/bin/bash
set -e

[[ -z "$1" ]] && echo "Usage: Please Specify environment !!!" && exit 1
./deploy/deploy.sh "deploy/deploy-$1.yml"