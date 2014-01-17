#
# Author:: Peter Bell <bellpeterm@gmail.com>
# Cookbook Name:: lgfile
# Attributes:: default
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

default['lgfile']['download_path'] = Chef::Config[:file_cache_path]
default['lgfile']['download_remote_path'] = "/"
default['lgfile']['download_host'] = "util1.util.sea.corp.w3data.com"
default['lgfile']['download_protocol'] = "http"
default['lgfile']['download_port'] = "80"
default['lgfile']['blocking'] = true