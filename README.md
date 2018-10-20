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

打开浏览器，访问 http://localhost:9292

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
RUN bundle install --jobs 8

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

打开浏览器访问 [http://localhost:9292]，测试网站是否运行成功。

查看products-service容器的IP
```
$ docker inspect --format '{{ .NetworkSettings.IPAddress }}' products-service
```

## 发布Docker镜像

* 发布到Docker Hub

登录Docker Hub [https://hub.docker.com/]，创建Docker Hub工程，