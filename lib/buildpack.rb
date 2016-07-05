# Encoding: utf-8
# ASP.NET Core Buildpack
# Copyright 2014-2016 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative './buildpack/compile/compiler.rb'
require_relative './buildpack/detect/detecter.rb'
require_relative './buildpack/release/releaser.rb'
require_relative './buildpack/shell.rb'
require_relative './buildpack/out.rb'
require_relative './buildpack/copier.rb'
require_relative './buildpack/services/optional_components.rb'
require 'yaml'

module AspNetCoreBuildpack
  def self.detect(build_dir)
    Detecter.new.detect(build_dir)
  end

  def self.compile(build_dir, cache_dir)
    compiler(build_dir, cache_dir).compile
    environment = ENV.to_hash
    vcap_services = environment.delete 'VCAP_SERVICES'
    #vcap_services = vcap_services ? YAML.load(vcap_services) : {}
    #puts("vcap_services = #{vcap_services}")
    optlCpts = {
      ibmdb: 'false',
      vcap_services: vcap_services ? YAML.load(vcap_services) : {}
    }
    parse_vcap_services(optlCpts)
    OptionalComponents.new(build_dir, shell, out, optlCpts)
    @optlCpts = optlCpts
  end

  def self.compiler(build_dir, cache_dir)
    Compiler.new(
      build_dir,
      cache_dir,
      LibunwindInstaller.new(build_dir, shell),
      DotnetInstaller.new(shell),
      Dotnet.new(shell),
      Copier.new,
      out)
  end
     
  def self.parse_vcap_services(optlCpts)
    unless optlCpts[:vcap_services].nil?
      optlCpts[:vcap_services].each do |service_type, service_data|
      puts("inside vcap_services parsing, service_type =  #{service_type}")   
        if 'dashDB'.eql?(service_type)
          optlCpts[:ibmdb] = 'true' 
          puts("service_type is dashDB and set to cliinstall = #{optlCpts[:ibmdb]} \n ")
        end
      end
    end
  end  
  

  def self.release(build_dir)
    Releaser.new.release(build_dir, compile.optlCpts)
  end

  def self.out
    @out ||= Out.new
  end

  def self.shell
    @shell ||= Shell.new
  end
  
  attr_reader :optlCpts
end
