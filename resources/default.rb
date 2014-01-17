#
# Author:: Peter Bell (<bellpeterm@gmail.com>)
# Cookbook Name:: lgfile
# Resource:: default
#
# Copyright:: 2014, Peter Bell
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

actions :download, :delete

attribute :name, :kind_of => String, :required => true, :name_attribute => true
attribute :path, :kind_of => String
attribute :hash, :kind_of => String
attribute :remote_path, :kind_of => String
attribute :host, :kind_of => String
attribute :protocol, :kind_of => String
attribute :port, :kind_of => Integer
attribute :blocking, :default => false
attribute :unzip, :default => true

attr_accessor :exists, :status, :is_zip