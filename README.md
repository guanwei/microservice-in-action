# 微服务架构与实践

> 微服务架构是一种架构模式，它提倡将单一应用程序划分成一组小的服务，服务之间相互协调、互相配合，为用户提供最终价> 值，每个服务运行在其独立的进程中，服务于服务间采用轻量级的通信机制互相沟通（通常是基于HTTP的RESTful API）。> 每个服务都围绕着具体业务进行构建，并且能够被独立第部署到生产环境、类生产环境等。另外，应尽量避免统一的、集中式的> 服务管理机制，对具体的一个服务而言，应根据业务上下文，选择合适的语言、工具对其进行构建。
<p align="right">--- [摘自马丁 * 富勒先生的博客](http://martinfowler.com/articles/microservices.html)</p>

## Hello World API

* 开发语言 --- Ruby
* Web框架 --- Grape

### API的具体实现

1. 创建项目目录products-service
```
$ mkdir products-service
$ cd products-service
```

2. 安装ruby 2.5.0

```
$ rbenv install 2.5.0
```

3. 设置当前项目ruby版本为2.5.0, 该命令会在当前目录下生成`.ruby-version`文件

```
$ rbenv local 2.5.0
```

4. 刷新rbenv环境，并检查当前ruby版本
```
$ rbenv rehash
$ ruby -v
```

5. 创建Gemfile文件，并添加如下内容：
```
source 'https://rubygems.org'          # 使用官方的Gems镜像

gem 'grape'
```

使用如下命令安装Gem：
```
$ bundle install
```

6. 创建api/api.rb文件，并添加如下内容：
```
require 'grape'
class API < Grape::API
  format :json

  get '/' do
    'Hello World'
  end
end
```

7. 新建lib/init.rb文件，并添加如下内容：
```
project_root = File.dirname(__FILE__) + '/..'
$LOAD_PATH << "#{project_root}/api"
require 'grape'
require 'api'
```

8. 新建文件config.ru，添加如下内容：
```
require_relative 'lib/init'
run Rack::Cascade.new [API]
```

9. 执行如下命令，启动web服务：
```
$ rackup
```

打开浏览器，访问 <http://localhost:9292>

### 代码测试

采用RSpec作为代码测试工具

1. 打开Gemfile，添加如下内容：
```
group :development, :test do
  gem 'rspec'
  gem 'rspec-its'
  gem 'byebug'
end
```

2. 初始化RSpec

```
$ bundle install
$ rspec --init      # 初始化RSpec
```

初始化命令将会生成两个文件：
```
.rspec                  # RSpec运行时首先加载的配置文件
spec/spec_helper.rb     # RSpec运行时的参数配置文件
```
3. 定义RSpec的Rake任务

首先，创建lib/tasks/spec.rake，并添加如下内容：
```
require 'rspec/core/rake_task'      # 引用RSpec库
RSpec::Core::RakeTask.new(:spec)    # 使用RSpec的方式定义Rake任务
```

接下来，在项目的根目录下新建Rakefile，并添加如下内容：
```
FileList['./lib/tasks/**/*.rake'].each{ |task| load task }  # 加载所有的rake文件
task default: [:spec]    # 将spec作为默认的rake任务
```

在Gemfile中加入如下内容：
```
gem 'rake'
```

并执行如下命令安装gem：
```
$ bundle install
```

查看当前可用的Rake任务：
```
$ bundle exe rake -T
```

接下来，使用如下命令执行该任务：
```
$ rake spec
```

### 测试API

使用rake-test对当前的API进行测试。

1. 修改Gemfile，并添加如下代码：
```
gem 'rack-test'
```

并执行如下命令安装gem：
```
$ bundle install
```

2. 修改spec/spec_helper.rb，添加相关的引用：
```
require 'rspec'
require 'rack/test'
require_relative '../lib/init'
...
```

3. 新建api的测试文件spec/api_spec.rb，并添加如下代码：
```
require 'spec_helper'

describe API do
  include Rack::Test::Methods

  describe 'get' do
    before do
      get("/")
    end

    it 'should return Hello world' do
      expect(last_response.body).to eq("\"Hello World\"")
    end

    it 'should return json format' do
      expect(last_response.content_type).to eq "application/json"
    end
  end
end

def app
  API
end
```

测试内容写好后，运行测试，因为默认的任务已经设置成spec，可以直接运行以下命令：
```
$ bundle exec rake
```

### 测试覆盖率统计

单元测试覆盖率是评价单元测试完整性的重要度量标准之一。SimpleCov是Ruby统计代码覆盖率比较方便的工具。

接下来，在当前的products-service中添加对测试覆盖率的统计。

1. 修改Gemfile，在 `group :development, :test do` 下添加如下代码：
```
gem 'simplecov', require: false
```

2. 在spec_helper.rb的开头添加如下代码，引用SimpleCov：
```
require 'simplecov'
```

并执行如下命令安装gem：
```
$ bundle install
```

3. 在spec_helper.rb的rspec代码片段前添加如下代码，完成初始化：
```
SimpleCov.start
```

4. 在spec_helper.rb的最后添加如下代码，设置最小的测试覆盖率：
```
SimpleCov.minimum_coverage 100
```

5. 重新运行Rake任务，此时会看到在结果中多了对测试覆盖率的的输出。
```
$ bundle exec rake
```

会自动在项目根目录下建立coverage 目录，打开 coverage/index.html 文件即可看到效果。

### 静态检查

主要检查代码和设计的一致性，代码对标准的遵循、可读性，代码的逻辑表达的正确性，代码结构的合理性等方面；可以发现违背程序编写标准的问题，程序中不安全、不明确和模糊的部分，找出程序中不可移植部分、违背程序编程风格的问题，包括变量检查、命名和类型审查、程序逻辑审查、程序语法检查和程序结构检查等内容。

这里使用Rubocop完成代码的静态检查。

1. 定义Rubocop

打开Gemfile，添加rubocop：
```
group :development, :test do
  ...
  gem 'rubocop'
end
```

并执行如下命令安装gem：
```
$ bundle install
```

2. 配置Rubocop

新建rubocop.yml文件，添加如下内容：
```
inherit_from: .rubocop_todo.yml

EmptyLinesAroundBlockBody:
  Exclude:
    - 'spec/**/*'

LineLength:
  Max: 120
  Exclude:
    - 'spec/**/*'
    - 'config/initializers/*'

MethodLength:
  Max: 20
  Exclude:
    - 'db/migrate/*'

Metrics/ClassLength:
  Max: 120

Metrics/PerceivedComplexity:
  Max: 10

WordArray:
  MinSize: 2
```

使用如下命令，产生`.rubocop_todo.yml`文件
```
$ rubocop --auto-gen-config
```

3. 定义Rake任务

通常，会将静态检查和Rake任务集成。

新建lib/tasks/quality/rubocop.rake文件, 并添加如下内容：
```
namespace :quality do
  begin
    require 'rubocop/rake_task'

    RuboCop::RakeTask.new(:rubocop) do |task|
      task.patterns = %w{
        app/**/*.rb
        config/**/*.rb
        lib/**/*.rb
        spec/**/*.rb
      }
    end
  rescue LoadError
    warn "rubocop not available, rake task not provided."
  end
end
```

查看rubocop对应的Rake任务
```
$ bundle exec rake -T
```

接下来，使用如下命令执行该任务
```
$ rake quality:rubocop
```

### 代码复杂度检查

这里使用Cane完成代码复杂度检查。

1. 定义Cane

打开Gemfile，添加Cane
```
group :development, :test do
  ...
  gem 'cane'
end
```

并执行如下命令安装gem：
```
$ bundle install
```

2. 定义Rake任务

新建lib/tasks/quality/cane.rake文件, 并添加如下内容：
```
namespace :quality do
  begin
    require 'cane'
    require 'cane/rake_task'
  rescue LoadError
    warn "cane not available, cane task not provided."
  else
    desc "Run cane to check quality metrics"
    Cane::RakeTask.new(:cane) do |cane|
      cane.abc_max       = 12
      cane.no_doc        = true
      cane.style_glob    = './{app,lib}/**/*.rb'
      cane.style_measure = 120
      cane.abc_exclude   = []
    end
  end
end
```

查看Cane对应的Rake任务
```
$ bundle exec rake -T
```

接下来，使用如下命令执行该任务
```
$ rake quality:cane
```

3. Rake任务集成

将Rubocop和Cane任务合并，定义成一个入口。

新建lib/tasks/quality.rake，并添加如下内容：
```
desc "Run cane and rubocop quality checks"
task quality: %w(quality:cane quality:rubocop)
```

这时，运行 `rake quality` 就能运行Rubocop和Cane了。

4. 默认Rake任务设置

还可以将RSpec、Rubocop以及Cane的运行统一设置成默认运行的Rake任务。

修改Rakefile，代码如下：
```
FileList['./lib/tasks/**/*.rake'].each{ |task| load task }
task default: [:quality, :spec]
```

## 构建Docker镜像

利用Docker的容器化技术，能够实现在一个节点上运行成百甚至上千的Docker容器，降低了节点数量增多带来的成本，每个容器都能独立运行一个服务。

### 定义Dockerfile

1. 在products-services目录下，新建Dockerfile文件，内容如下：
```
FROM ruby:2.5.0
MAINTAINER docker-library <docker-library@github.com>

RUN apt-get update -y

ADD . /app

WORKDIR /app
RUN bundle install --jobs=8 --retry=3

EXPOSE 9292

CMD ["rackup","-o","0.0.0.0"]
```

执行`docker images`，显示本地docker镜像，如果提示如下，说明Docker进程并未运行
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

2. 构建Docker镜像

使用docekr build构建Docker镜像
```
$ docker build -t products-service .
```

查看镜像是否创建好
```
$ docker images | grep products-service
```

## 运行Docker容器

通过products-service镜像，创建products-service容器
```
$ docker run --name products-service -d -it -p 9292:9292 products-service
```

查看当前products-service所在容器的运行情况
```
$ docker ps -a | grep products-service
```

打开浏览器访问 <http://localhost:9292>，测试网站是否运行成功。

查看products-service容器的IP
```
$ docker inspect --format '{{ .NetworkSettings.IPAddress }}' products-service
```

## 发布Docker镜像

* 发布到Docker Hub

登录Docker Hub <https://hub.docker.com/>，依次点击 Create -> Create Automated Build -> Create Auto-build Github，选择`microservice-in-action`，Repository Name填写为`products-service`, Dockerfile Location填写为 `products-service/`，简单填写Short Description，然后点击Create。

点击 Build Settings -> Trigger，手动触发一个Docker镜像的build。

* 发布到私有的Docker仓库

可以使用如下脚本，将Docker镜像发布到内部的Docker仓库。
```
#!/bin/bash

DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL
DOCKER_REGISTRY_USER_NAME=$DOCKER_REGISTRY_USER_NAME
APP_NAME=$APP_NAME

BUILD_NUMBER=${BUILD_NUMBER:-dev}
VERSION=${MAJOR_VERSION}.$BUILD_NUMBER

FULL_TAG=$DOCKER_REGISTRY_URL/$DOCKER_REGISTRY_USER_NAME/$APP_NAME:$VERSION
FILE_NAME=$APP_NAME-$VERSION

echo "Building Docker image..."
docker build --tag $FULL_TAG .

if [ $DOCKER_REGISTRY_URL != "localhost" ]; then
  echo "Pushing Docker image to Registry..."
  docker push $FULL_TAG
fi
```

* 发布到云存储

可以将Docker及镜像导成tar包，存储到AWS的S3上，示例代码如下：
```
#!/bin/bash

APP_NAME=$APP_NAME

BUILD_NUMBER=${BUILD_NUMBER:-dev}
VERSION=${MAJOR_VERSION}.$BUILD_NUMBER

S3_BUCKET=$S3_BUCKET

FULL_TAG=$APP_NAME:$VERSION
FILE_NAME=$APP_NAME-$VERSION

mkdir -p target

echo "Saving Docker image to local file..."
docker save -o target/$FILE_NAME.tar $FULL_TAG

echo "Compressing local Docker image..."
gzip --force target/$FILE_NAME.tar

echo "Uploading docker image to S3..."
aws s3 mv target/$FILE_NAME.tar.gz s3://$S3_BUCKET/$APP_NAME/$FILE_NAME.tar.gz
```

## 部署Docker镜像

### 基础设施AWS

对当前的products-service而言，基础设施主要包括：
* 虚拟私有云（Virtual Private Cloud）
* 安全组（Security Group）
* 计算实例（Elastic Compute Cloud）
* 自动扩容机制（Auto scaling）
* DNS解析（Route 53）

### 基础设施自动化

AWS提供[CloudFormation]（http://aws.amazon.com/cloudformation/）帮助用户在AWS上高效创建基础设施。

使用CloudFormation创建相关的基础设施，主要包括：
* AWS EC2节点的创建
* AWS Security Group的创建
* AWS DNS解析的配置
* AWS Autoscaling Group自动扩容机制的创建

如下为CloudFormation的配置文件：
```
{
  "Resources": {
    "instanceSecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupDescription": "Security Group",
        "VpcId": "vpc-xxxxx",
        "SecurityGroupIngress": [
          {
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "CidrIp": "0.0.0.0/0"
          },
          {
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIp": "0.0.0.0/0"
          }
        ],
        "Tags": [
          {
            "Key": "Name",
            "Value": "products-service"
          }
        ]
      }
    },
    "loadBalancerSecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupDescription": "Security Group",
        "VpcId": "vpc-xxxxx",
        "SecurityGroupIngress": [
          {
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIp": "0.0.0.0/0"
          }
        ],
        "Tags": [
          {
            "Key": "Name",
            "Value": "products-service"
          }
        ]
      }
    },
    "dnsRecord": {
      "Type": "AWS::Route53::RecordSet",
      "Properties": {
        "Comment": "Public Record",
        "HostedZoneName": "products-service.test.microservice-in-action.com",
        "Type": "A",
        "AliasTarget": {
          "DNSName": {
            "Fn::GetAtt": [
              "loadBalancer",
              "DNSName"
            ]
          },
          "HostedZoneId": {
            "Fn::GetAtt": [
              "loadBalancer",
              "CanonicalHostedZoneNameID"
            ]
          }
        }
      }
    },
    "loadBalancer": {
      "Type": "AWS::ElasticLoadBalancing::LoadBalancer",
      "Properties": {
        "Scheme": "internal",
        "Subnets": [
          "subnet-xxxxxx",
          "subnet-xxxxxx"
        ],
        "SecurityGroups": [
          {
            "Ref": "loadBalancerSecurityGroup"
          }
        ],
        "Listeners": [
          {
            "Protocol": "HTTP",
            "LoadBalancerPort": 80,
            "InstancePort": 80
          }
        ],
        "HealthCheck": {
          "Target": "HTTP:80/diagnostic/status/heartbeat",
          "HealthyThreshold": 2,
          "UnhealthyThreshold": 4,
          "Interval": 10,
          "Timeout": 8
        },
        "CrossZone": true,
        "ConnectionDrainingPolicy": {
          "Enabled": true,
          "Timeout": 30
        },
        "Tags": [
          {
            "Key": "Name",
            "Value": "products-service"
          }
        ]
      }
    },
    "dnsRecordservices": {
      "Type": "AWS::Route53::RecordSet",
      "Properties": {
        "Comment": "Public Record",
        "HostedZoneName": "products-service.test.microservice-in-action.com",
        "Name": "products-service.test.microservice-in-action.com",
        "Type": "A",
        "AliasTarget": {
          "DNSNAME": {
            "Fn::GetAtt": [
              "loadBalancer",
              "DNSName"
            ]
          },
          "HostedZoneId": {
            "Fn::GetAtt": [
              "loadBalancer",
              "CanonicalHostedZoneNameID"
            ]
          }
        }
      }
    },
    "launchConfiguration-xxxxxx": {
      "Type": "AWS::AutoScaling::LaunchConfiguration",
      "Properties": {
        "IamInstanceProfile": {
          "Ref": "iamInstanceProfile"
        },
        "ImageId": "ami-xxxxxx",
        "InstanceType": "t2.medium",
        "InstanceMonitoring": true,
        "SecurityGroups": [
          {
            "Ref": "instancesSecurityGroup"
          }
        ]
      }
    },
    "autoScallingGroup-xxxxxx": {
      "CreationPolicy": {
        "ResourceSignal": {
          "Count": 1,
          "Timeout": "PT5M"
        }
      },
      "Type": "AWS::AutoScalling::AutoScallingGroup",
      "Proerties": {
        "AvailabilityZones": [
          "ap-southeast-2b",
          "ap-southeast-2a"
        ],
        "Cooldown": "120",
        "DesiredCapacity": "1",
        "HealthCheckType": "ELB",
        "LaunchConfigurationName": {
          "Ref": "launchConfiguration-xxxxxx"
        },
        "LoadBalancerNames": [
          {
            "Ref": "loadBalancer"
          }
        ],
        "MaxSize": "1",
        "MinSize": "1",
        "Tags": [
          {
            "Key": "Name",
            "Value": "products-service",
            "PropagateAtLaunch": true
          },
          {
            "Key": "application",
            "Value": "products-service",
            "PropagateAtLaunch": true
          }
        ],
        "VPCZoneIdentifier": [
          "subnet-xxxxxx",
          "subnet-xxxxxx"
        ]
      }
    },
    "scheduledAction-xxxxxx": {
      "Type": "AWS::AUtoScalling::ScheduledAction",
      "Properties": {
        "AutoScallingGroupName": {
          "Ref": "autoScallingGroup-xxxxxx"
        },
        "DesiredCapacity": 0,
        "MaxSize": 0,
        "MinSize": 0,
        "Recurrence": "0 11 * * *"
      }
    }
  },
  "Outputs": {
    "iamRoleArn": {
      "Value": "products-service-iam-role"
    },
    "DNSName": {
      "Value": {
        "Ref": "dnsRecord"
      }
    },
    "loadBalancerAddress": {
      "Value": {
        "Fn::GetAtt": [
          "loadBalancer",
          "DNSName"
        ]
      }
    }
  }
}
```

## 部署Docker镜像

之前我们已经把products-service的Docker镜像发布到了Docker Hub，因此可以使用下面的脚本`docker-deploy.sh`完成Docker镜像的部署。
```
#!/bin/bash
set -e

DOCKER_REGISTRY_USER_NAME="guanwei"
APP_NAME="products-service"
APP_VERSION="latest"

FULL_TAG=$DOCKER_REGISTRY_USER_NAME/$APP_NAME:$APP_VERSION

echo "Pulling Dokcer image from Registry"
docker pull $FULL_TAG

echo "Launching Docker Container"
docker run -d -p 80:9292 $FULL_TAG
```

## 自动化部署

1. 首先，实现自动化部署脚本`deploy/deploy.sh`，如下：
```
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
```

为了实现当EC2节点启动后，能自动执行Docker镜像获取和部署，将docker-deploy.sh的代码嵌入到CloudFormation的User Data中。

2. 定义生产环境配置文件`deploy/deploy-prod.yml`
```
app:
  name: products-service

docker:
  image: guanwei/products-service:latest

aws:
  vpc: vpc-xxx
  region: xxx
  subnets:
    - subnet-xxx-A
    - subnet-xxx-B
  load_balancers:
    name: products-service-xxx
    dns: products-service-elb.xxx.amazonaws.com
  instances:
    type: t2.micro
    min: 1
    max: 2

splunk:
  host: splunk-prod-xxx.microservice-in-action.com
  index: products-service

nagios:
  host: nagios-xxx.microservice-in-action.com
```

3. 定义测试环境配置文件`deploy/deploy-test.yml`

```
app:
  name: products-service

docker:
  image: guanwei/products-service:latest

aws:
  vpc: vpc-xxx
  region: xxx
  subnets:
    - subnet-xxx-A
    - subnet-xxx-B
  load_balancers:
    name: products-service-xxx
    dns: products-service-elb.xxx.amazonaws.com
  instances:
    type: t2.micro
    key_pair: products-service
    min: 1
    max: 2

splunk:
  host: splunk-prod-xxx.microservice-in-action.com
  index: products-service

nagios:
  host: nagios-prod-xxx.microservice-in-action.com
```

通常情况下，为了保持安全性和隔离性，生产环境和测试环境试运行在两个独立的AWS账号下。

## 持续集成环境

这里选用[Travis-CI](https://travis-ci.org/)作为持续交付工具。

新建`.travis.yml`
```
sudo: true
dist: trusty

jobs:
  include:
  - stage: build
    install: bundle install --jobs=8 --retry=3
  - stage: tests
    script: bundle exec rake
```