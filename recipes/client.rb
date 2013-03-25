#
# Cookbook Name:: mysql
# Recipe:: client
#
# Copyright 2008-2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Include Opscode helper in Recipe class to get access
# to debian_before_squeeze? and ubuntu_before_lucid?
::Chef::Recipe.send(:include, Opscode::Mysql::Helpers)

case node['platform']
when "windows"
  package_file = node['mysql']['client']['package_file']
  remote_file "#{Chef::Config[:file_cache_path]}/#{package_file}" do
    source node['mysql']['client']['url']
    not_if { File.exists? "#{Chef::Config[:file_cache_path]}/#{package_file}" }
  end

  windows_package node['mysql']['client']['packages'].first do
    source "#{Chef::Config[:file_cache_path]}/#{package_file}"
  end
  windows_path node['mysql']['client']['bin_dir'] do
    action :add
  end
  def package(*args, &blk)
    windows_package(*args, &blk)
  end
when "mac_os_x"
  include_recipe 'homebrew'
end

# Download package files if necessary
unless platform_family?(%w{mac_os_x windows})
  unless node['mysql']['client']['package_files'].size == node['mysql']['client']['package_urls'].size
    Chef::Log.warn "There should be a node['mysql']['client']['package_urls'] entry for each ['mysql']['client']['package_files'] entry"
  end
  node['mysql']['client']['package_files'].each_with_index do |filename,i|
    remote_file File.join(node['mysql']['client']['package_dir'], filename) do
      source node['mysql']['client']['package_urls'][i] || nil
      action :create_if_missing
    end
  end
end

node['mysql']['client']['packages'].each_with_index do |mysql_pack,i|
  package mysql_pack do
    if node['mysql']['client']['package_files'][i]
      source File.join(node['mysql']['client']['package_dir'],
                       node['mysql']['client']['package_files'][i] )
    end
    action :install
  end
end

if platform? 'windows'
  ruby_block "copy libmysql.dll into ruby path" do
    block do
      require 'fileutils'
      FileUtils.cp "#{node['mysql']['client']['lib_dir']}\\libmysql.dll", node['mysql']['client']['ruby_dir']
    end
    not_if { File.exist?("#{node['mysql']['client']['ruby_dir']}\\libmysql.dll") }
  end
end
