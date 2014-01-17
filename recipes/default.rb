#
# Cookbook Name:: lgfile
# Recipe:: default
#
# Copyright 2014, Peter Bell
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

chef_gem "zip"

# Install aria2
case node['platform']
when "windows"
  Chef::Log.info("detected Windows")
  include_recipe "chocolatey::default"
  chocolatey "aria2"
### Workaround for OSX 10.8 Homebrew build fail for aria2 1.18
#when "mac_os_x"
#  Chef::Log.info("detected OSX")
#  unless ::File.exists?('/usr/local/bin/aria2c')
    
#    Chef::Log.info("aria2 not found, installing")
#    
#    package "gnutls"
#    package "curl-ca-bundle"
#    
#    remote_file "#{Chef::Config[:file_cache_path]}/aria2-1.17.1.zip" do
#      source "#{node['lgfile']['download_protocol']}://#{node['lgfile']['download_host']}/aria2-1.17.1.zip"
#    end
 
#    ruby_block "install_lgfile" do
     # block do
      #  require 'zip/zipfilesystem'
      #  Zip::ZipFile.open("#{Chef::Config[:file_cache_path]}/aria2-1.17.1.zip") do |zip_file|
      #    zip_file.each do |f|
      #      f_path=File.join("/usr/local/Cellar", f.name)
      #      FileUtils.mkdir_p(File.dirname(f_path))
      #      zip_file.extract(f, f_path) unless File.exist?(f_path)
      #    end
      #  end        
     # end
     # action :create
 #   end

 #   execute "correct-aria-permissions" do
 #     command "chmod a+rx /usr/local/Cellar/aria2/1.17.1/bin/aria2c"
 #   end

 #   execute "link-aria" do
 #     command "brew link aria2"
 #   end
 # else
 #   Chef::Log.info("aria2 found; not installing")
 # end
  
when "*"
  Chef::Log.info("detected generic")
  package "aria2"
end

# Create default downlod directory
directory node[:lgfile][:download_path] do
  user node[:chef_handler][:root_user] unless node['platform'] == "windows"
  group node[:chef_handler][:root_group] unless node['platform'] == "windows"
  mode "755"
  action :create
end
