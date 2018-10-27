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
    key_pair: products-service
    min: 1
    max: 2

splunk:
  host: splunk-prod-xxx.microservice-in-action.com
  index: products-service

nagios:
  host: nagios-prod-xxx.microservice-in-action.com
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
  host: splunk-test-xxx.microservice-in-action.com
  index: products-service

nagios:
  host: nagios-test-xxx.microservice-in-action.com
```

通常情况下，为了保持安全性和隔离性，生产环境和测试环境试运行在两个独立的AWS账号下。

## 持续集成环境

持续交付流水线通常包括3个阶段。
* 提交阶段
* 验证阶段
* 发布阶段
* 部署阶段

### 提交阶段

提交阶段主要检测代码库的变化，并按照配置触发相应的处理。
* 代码编译
* 静态检查
* 运行单元测试

### 验证阶段

验证阶段主要进行功能、性能等的验证。

* 运行集成测试
* 运行用户行为测试
* 运行组件测试
* 运行性能测试

### 构建阶段

构建阶段主要任务是构建部署包。

> ### 语义化版本
> 语义化版本是指对于一个给定的版本号，将其定义为MAJOR.MINOR.PATCH(主、次、补丁)，其变化的规律通常指：
> * MAJOR version (主版本) 会在API发生不可向下兼容的改变时增大。
> * MINOR version (次版本) 会在有向下兼容的新功能加入时增大。
> * PATCH version (补丁版本) 会在有向下兼容的缺陷被修复时增大。

### 发布阶段

发布阶段主要将部署包发布到具体的环境中。

通常包括三类：
* 测试环境
* 类生产环境
* 生产环境

| 测试环境 | 类生产环境 | 生产环境
--- | --- | --- | ---
触发方式 | 自动 | 手动 | 手动
数据来源 | 模拟数据 | 真实数据 | 真实数据
使用目的 | 主要用于开发团队内部验证功能为主 | 基于生产环境的真实数据为业务部门进行演示 | 为用户提供真实的服务

调用如下命令部署测试环境和生产环境：
```
$ deploy/deploy.sh deploy-test.yml  # 部署测试环境
$ deploy/deploy.sh deploy-prod.yml  # 部署生产环境
```

可以抽象出一个更简洁的不同环境的部署脚本`ci-deploy.sh`
```
#!/bin/bash
set -e

[[ -z "$1" ]] && echo "Usage: Please Specify environment !!!" && exit 1
./deploy/deploy.sh "deploy/deploy-$1.yml"
```

部署测试环境和生产环境可以简化为：
```
./ci-deploy.sh test  # 部署测试环境
./ci-deploy.sh prod  # 部署生产环境
```

可以使用[Travis-CI](https://travis-ci.org/)作为持续交付工具，这里省略部署部分。

新建`.travis.yml`
```
language: ruby
rvm: 2.5.0
gemfile: products-service/Gemfile

install: bundle install --jobs=8 --retry=3
before_script: cd products-service
script: bundle exec rake
```

## 日志聚合

如果没有合适的工具，从成百个节点上的上百个日志文件中搜索出错日志会变得很困难，同时也意味着定位变得很困难，同时也意味着定位问题、发现问题的成本将随着节点数量的增多呈指数增加。

日志聚合工具主要以Splunk和LogStash为主。

* ### Splunk

Splunk (<http://www.splunk.com/>) 是一款功能强大的日志管理工具，可以用多种方式来添加日志，生成图形化报表。它最强大的功能是搜索。Splunk分为免费版和收费版，免费版每天索引量最大为500MB。Splunk的主要功能包括：
* 日志聚合
* 日志搜索
* 语义提取
* 对结果进行分组、联合、拆分和格式化
* 强大的可视化功能
* 电子邮件提醒功能

Splunk可以单机部署，也可以分布式部署。

* ### LogStash

LogStash (<http://www.logstash.net>) 是一款开源的日志管理工具，使用JRuby语言实现。主要功能包括：
* 收集日志

LogStash可以从多个数据源获取日志，譬如标准输入、日志文件或者是syslog等。同时内嵌支持多种日志的格式，如系统日志、Web服务器日志、错误日志、应用日志等。如果日志的输入是syslog，用户不必在每台服务器上安装日志代理（Log Agent），默认的rsyslog客户端就可以直接同步日志。

* 过滤日志

LogStash内置了许多过滤器，如grep、split、multiline等，能够方便地为客户定制过滤策略。

* 结果输出

除了能将日志内容输出到标准输出，LogStash还能和ElasticSearch、MongoDB等配合使用。实际上、LogStash通常会和ElastiSearch以及Kibana配合使用，组成ELK（ElasticSearch作为日志的搜索引擎，LogStash作为日志的处理引擎，Kibana作为前端的报表展示）。

本例中使用Splunk作为日志聚合工具。

### 安装Splunk索引器

从Splunk官网下载Splunk Enterprise或者Splunk Light版本进行安装。默认，索引器和搜索器是安装在一起的。

### 安装Splunk转发器

从官方网站下载Splunk Forwarder，并配置好索引器的IP地址和端口号。然后设置inputs.conf文件，默认在$SPLUNK_DIR/etc/system/local/inputs.conf，并在其中添加如下配置：
```
[monitor:///var/log/httpd/error.products_service.log]
index = products_service
sourcetype = products_service_http_error_log

[monitor:///var/log/httpd/access.products_service.log]
index = products_service
sourcetype = products_service_http_access_log

[monitor:///var/log/products_service/production.log]
index = products_service
sourcetype = products_service_production_log
```

### 日志查找

譬如，想要搜索products-service昨天的关键字包含`error`的日志，可以用如下方式进行搜索：
```
index=products_service sourcetype=products_service_production_log earliest=-1d@d latest=-0d@d error
```

### 告警设置

设置告警主要分成三步。
1. 保存搜索条件“Save Search”，为后续的告警设置条件。
2. 设置”告警阈值“，超过阈值时触发告警。
3. 定义”告警响应“，告警触发后的处理动作。

## 监控与告警

关于监控，目前业界已经存在很多成熟的产品，譬如Ganglia、Zabbix、NewRelic、Nagios和OneAPM等。

这里使用Nagios作为监控工具。Nagios安装完成后，会在`/usr/local/nagios`目录下生成相应的主机、服务、命令、模板等配置文件。

目录名称 | 作用
--- | ---
bin | Nagios可执行程序所在的目录
etc | Nagios配置文件所在的目录
sbin | Nagios cgi文件所在的目录，也就是执行外部命令所需的文件所在的目录
share | Nagios网页存放路径
libexec | Nagios外部插件存放目录
var | Nagios日志文件、Lock等文件所在的目录
var/archives | Nagios日志自动归档目录
var/rw | 用来存放外部命令文件的目录

Nagios相关配置文件的名称及用途。

配置文件 | 作用
--- | ---
nagios.cfg | Nagios的主配置文件
objects | objects是一个目录，存放配置模板
objects/commands.cfg | 命令定义配置文件，其中定义的命令可以被其他配置文件引用
objects/templates.cfg | 定义主机和服务的一个模板配置文件，可以在其他配置文件中引用
objects/timeperiods.cfg | 定义Nagios监控时间段的配置文件
objects/windows.cfg | 监控Windows主机的一个配置文件模板，默认没有启用此文件

### 监控products-service

1. 定义主机和服务监控
```
define host {
  use             business-hours-service
  hostgroups      products-service
  host_name       products-service.corp
  address         products-service.internal.corp
  check_command   check_dig!$HOSTADDRESS$
}

define service {
  use                    generic-service
  host_name              products-service.corp
  service_description    HTTPS  Healthcheck
  check_command          check_http_health
}
```

2. 实现监控命令

在`commands.cfg`中依次添加check_dig以及check_http_health命令
```
# 'check_http_health' command definition
define command {
  command_name    check_dig
  command_line    /usr/lib/nagios/plugins/check_dig --query_address $ARG1$ -H $HOSTADDRESS$ -t 30
}

# 'check_http_health' command definition
define command {
  command_name   check_http_health
  command_line   $USER1$/check_http -H $HOSTADDRESS$ -u "/diagnostic/status/nagios" -w 50 -c 60 -e "HTTP/1.0 200","HTTP/1.1 200" $ARG1$ -f follow
}
```

3. 定义监控时间段

通常，我们都将监控时间段定义在template中。
```
define service {
  contact_groups             OperationsTeam
  name                       Working-hours-service-tmpl
  action_checks_enabled      1
  notifications_enabled      1
  check_period               24x7
  normal_check_interval      1440
  retry_check_interval       5
  max_check_attempts         10    # when a non-OK state is returned
  first_notification_delay   0
  notification_options       w,u,c,r
}
```

4. 定义联系人

在`contact.cfg`中定义发生异常时待通知的联系人。
```
define contact {
  contact_name         products-service-admin
  alias                Nagios Admin
  use                  generic-contact
  email                products-serviced@gmail.com
}

define contact {
  contact_name         products-service-admin-pager
  alias                Nagios Admin(Phone)
  use                  generic-contact-sms
  pager                xxxxxx
}
```

### 告警

针对每个服务，都应该提供有效的告警机制，确保当前服务出现异常时，能够准确有效地通知到责任人，并及时解决问题。

PagerDuty是一款能够在系统出现问题时及时发送消息提醒的应用，提醒方式包括屏幕显示、电话呼叫、短信通知、邮件通知等。同时还能够集成现有的即时消息通信工具，譬如Slack、Skype以及第三方的监控应用，譬如Newrelic、Nagios、Splunk等。在规定的时间内无人应答时，PageDuty还能自动将消息的重要性级别提高。

## 功能迭代

有了基础设施、构建、部署、持续交付流水线以及相应的运维保障机制，接下来，我们可以通过频繁且持续迭代的方式，完成products-service需要的功能。

将products-service的实现划分成几个小任务，一方面便于团队跟踪进度，另一方面也能帮助团队在单位时间内聚焦某一个任务。

1. 定义Product
2. 持久化Product
3. 获取Product
4. 定义API的输出

### 定义模型

```
class Product
  include Virtus.model

  attribute :id,        Integer
  attribute :name,      String
  attribute :price,     Float
  attribute :category,  String
end
```

这里使用 rom-sql (<https://github.com/rom-rb/rom-sql>) 完成Product的存储以及获取。
```
class ProductRepository
  class << self
    def find(id)
      relation.as(:products).find(id).first || raise(Error, 'Product not find')
    end

    private
    def relation
      Database.db.relation(:products)
    end
  end
end
```

另外，需要对rom-sql的relation以及数据库和model之间的映射进行配置：
```
def self.setup_relations(rom)
  rom.relation(:products) do
    def find(id)
      where(id: id)
    end
  end
end

def self.setup_mappings(rom)
  rom.mappers do
    define(:products) do
      model ProductService::Product
    end
  end
end
```

### 定义表现形式

### 实现API

products-service实现的代码结构如下：
```
|-- app
|    |-- api.rb
|    |-- models
|    |     |
|    |     --- product.rb
|    |-- repositories
|    |     |-- product_repository.rb
|    |     --- record_not_found_error.rb
|    ---- representers
|          |-- product_representer.rb
|          --- products_representer.rb
```

### 服务描述文件

服务描述文件主要包括如下几个部分：
* 服务介绍
* 维护者信息
* 服务的SLA
* 服务运行环境
* 开发、测试、构建和部署
* 监控和告警

服务描述文件模板：
```
1. 服务介绍
  * 服务名称
  * 服务功能
2. 服务维护者
  * 记录服务的维护者，通常是能直接联系到的个人
3. 服务可用期（SLA，Service Level Agreements）
  * 服务可用期，譬如，周一 ~ 周五（9:00 ~ 19:00）
4. 运行环境
  * 生产环境地址
    譬如 http://product-service.vendor.com
  * 测试环境地址
    譬如 http://product-service.test.vendor.com
5. 开发（描述开发相关的信息），通常包括但不限于以下几项。
  * 如何搭建开发环境
  * 如何运行服务
  * 如何调试
6. 测试（描述测试相关的信息），通常包括但不限于以下几项。
  * 测试策略
  * 如何运行测试
  * 如何查看测试的统计结果，譬如覆盖率、运行时间
7. 构建（描述持续集成以及构建的信息），通常包括但不限于以下几项。
  * 持续集成环境
  * 持续集成流程描述
  * 构建后的部署包发布
8. 部署（描述部署相关的信息），通常包括但不限于以下几项。
  * 如何部署到不同环境
  * 部署后的功能验证
9. 运维（描述运维相关的信息），通常包括但不限于以下几项。
  * 日志聚合的访问URL
  * 监控信息的访问URL
```

## 微服务与持续交付

### 持续交付的核心

* 小批量价值流动
* 频繁可发布
* 快速反馈

### 微服务架构与持续交付

在微服务架构中，由于每个服务都是一个独立的、可部署的业务单元。因此，每个服务也应该对应着一套独立的持续交付流水线。

### 开发

* 独立代码库
* 服务说明文件
* 代码所有权归团队
* 有效的代码版本管理工具
* 代码静态检查工具
* 易于本地运行

### 测试

* 集成测试的二义性
* Mock与Stub
* 接口测试
* 测试的有效性

### 持续集成

### 部署

1. 部署环境

* 基于IAAS层
* 基于PAAS层
* 基于数据中心
* 基于容器技术

2. 部署方式

* 手动部署
* 脚本部署
* 基础设施部署自动化
* 应用部署自动化
* 镜像部署
* 容器部署

### 运维

* 监控
* 告警
* 日志聚合

## 微服务与轻量级通信机制

### 同步通信与异步通信

### 远程调用RPC

RPC又称远程过程调用，是一种典型的分布式节点间同步通信的实现方式。远程过程调用采用客户端/服务端的模式，请求的发起者是客户端，提供响应的是服务器端。

#### 远程过程调用的弊端

* 耦合度高
* 灵活性差

### REST

REST是近几年使用比较广泛的分布式节点间同步通信的实现方式。

#### REST的核心

* 资源
* 表述
* 状态转移
* 统一接口

客户端操作资源的4种方式：
* GET 用来获取资源
* POST 用来新建资源
* PUT 用来更新资源
* DELETE 用来销毁资源

#### REST的优势

由于HTTP本身的无状态性，使用REST，能够有效保持服务/应用的无状态性，利于将来的水平伸缩。

#### REST的不足

* 如何标准化资源结构
* 如何有效处理相关资源的链接

### HAL

HAL的实现基于REST，并有效地解决了REST中资源结构标准化和如何有效定义资源链接的问题。

HAL将资源分为三个基本的部分：
* 状态
* 链接
* 子资源

```
{
  "_links": {...},
  state": {...},
  "_embedded": {
    "category": {
      "_links": {...},
      "state": {...}
    },
    ...
  }
}
```

### 消息队列

消息队列是一种处理节点之间异步通信的实现方式。发送消息的一端称为发布者，接收消息的一端称为消费者。

#### 核心部分

* 持久性
* 排队标准
* 安全策略
* 清理策略
* 处理通知

#### 访问方式

* 拉模式

通常在拉模式下，一般存在一个发布者和一个消费者。

* 推模式

通常在推模式下，一般存在多个消费者，也称他们为订阅者。

#### 消息队列的优点

* 服务间解耦
* 异步通信
* 消息的持久化以及恢复支持

#### 消息队列的缺点

* 实现复杂度增加
* 平台或者协议依赖
* 维护成本高

### 后台任务处理系统

后台任务处理系统主要包括如下几部分：
* 任务

任务是指后台处理系统中可执行的最小单元。

* 队列

队列主要用于存储任务，并提供任务执行失败后的错误处理机制，譬如失败重试、任务清理等。目前大多数后台任务处理系统通常采用Redis作为队列的实现机制。

* 执行器

执行器主要负责从队列中获取任务，并执行任务。后台系统运行时可以指定一个或者多个执行器。

* 定时器

定时器主要设置执行器运行的周期，譬如每1分钟或者3分钟运行执行器来执行任务。

#### 服务回调

通常会保持任务的轻量级，不会再任务中做过多的逻辑，而是尽量做到由任务回调具体的服务来完成交互。

#### 后台服务的优点

* 轻量级通信机制
* 维护成本低
* SDK及API支持

| 远程方法调用 | REST | HAL | 消息队列 | 后台任务系统
---|---|---|---|---
通信方式 | 同步通信 | 同步或异步通信 | 同步或异步通信 | 异步通信 | 异步通信
平台依赖性 | 强 | 平台无关 | 平台无关 | 强 | 强
语言支持 | 好 | 语言无关 | 语言无关 | 好 | 中
学习成本 | 高 | 低 | 低 | 高 | 低
维护成本 | 高 | 低 | 低 | 高 | 低

## 微服务与测试

### 微服务的结构

* 业务模型
* 业务逻辑
* 模型存储
* 资源定义
  * 表述内容
  * 描述格式
* 网关集成

### 微服务的测试策略

* 单元测试
* 接口测试
* 集成测试
* 组件测试
* 端到端测试
