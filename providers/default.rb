#
# Author:: Peter Bell (<bellpeterm@gmail.com>)
# Cookbook Name:: lgfile
# Provider:: default
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

require 'fileutils'
require 'mixlib/log'
require 'net/http'
require 'time'

#check if file is currently downloading
def running?
  processes = if node["platform_family"] == "windows" then
    `powershell.exe -Command \"(Get-Process | Where-Object {$_.Name -eq \'*aria*\'}).count\"`.chop.to_i
  else  
    cmd = Mixlib::ShellOut.new("pgrep -f #{new_resource.name}")
    pgrep = cmd.run_command
    pgrep.stdout.length
  end
  processes > 0
end

def unzip_to_folder (unzipped_folderpath_local, filepath_local)
  return false if [ "" , null ].include?(unzipped_folderpath_local)
  require 'zip'
  ::File.umask(0022)
  FileUtils.rm_rf(Dir.glob("#{unzipped_folderpath_local}/*")) unless "#{unzipped_folderpath_local}/" == "/"
  Zip::ZipFile.open("#{Chef::Config[:file_cache_path]}/#{new_resource.name}") do |zip_file|
    zip_file.each do |f|
      f_path=::File.join("#{unzipped_folderpath_local}", f.name)
      FileUtils.mkdir_p(::File.dirname(f_path))
      zip_file.extract(f, f_path) unless ::File.exist?(f_path)
    end
  end
  FileUtils.touch unzipped_folderpath_local, :mtime => ::File.mtime("#{filepath_local}")
  ::File.delete filepath_local
end

def load_current_resource
  @current_resource = Chef::Resource::Lgfile.new(@new_resource.name)
  @current_resource.path(@new_resource.path ? @new_resource.path : node["lgfile"]["download_path"])
  @current_resource.protocol(@new_resource.protocol ? @new_resource.protocol : node["lgfile"]["download_protocol"])
  @current_resource.host(@new_resource.host ? @new_resource.host : node["lgfile"]["download_host"])
  @current_resource.port(@new_resource.port ? @new_resource.port : node["lgfile"]["download_port"].to_i)
  @current_resource.remote_path(@new_resource.remote_path ? @new_resource.remote_path : node["lgfile"]["download_remote_path"])
  
  #Contruct local file path + name
  filedir = "#{@current_resource.path}#{"/" unless @current_resource.path.match("/$")}"
  filepath = "#{filedir}#{@current_resource.name}"
  
  #Check if file is a zip file
  if @current_resource.name.match(/\.zip$/)
    @current_resource.is_zip = true 
    unzipped_folderpath = "#{filedir}#{@current_resource.name.split(".")[0...-1].join(".")}"
  end
  
  #Determine modify time of existing file or folder
  filetime = if @current_resource.is_zip and ::File.exists?(unzipped_folderpath) then
    ::File.mtime(unzipped_folderpath)
  else
    ::File.exists?(filepath) ? ::File.mtime(filepath) : Time.new(0)
  end
  
  #Create the status attribute if it is not already set
  node.set_unless["lgfile"]["files"][@current_resource.name] = false

  #Check the current status
  filestatus = node["lgfile"]["files"][@current_resource.name]

#  check http headers for modify date
  httpcheck = Net::HTTP.new(@current_resource.host,@current_resource.port)
  httpcheck.use_ssl = true if @current_resource.protocol == "https"
  httpresponse = httpcheck.request_head("#{"/" unless @current_resource.remote_path.match("^/")}#{@current_resource.remote_path}#{"/" unless @current_resource.remote_path.match("/$")}#{@current_resource.name}")
  #Mixlib::Log.debug(httpresponse.to_s)

  remotefiletime = Time.new(0)
  remotefiletime = Time.parse(httpresponse['Last-Modified']) if httpresponse['Last-Modified']
  
#  Set current status based on file time and unzip status  
  if remotefiletime == Time.new(0) then
    #Mixlib::Log.info("Couldn't determine status of #{@current_resource.name}")
    @current_resource.status = 3
    @current_resource.exists = false
  elsif remotefiletime == filetime then
    #Mixlib::Log.info("#{@current_resource.name} is current")
    #file is downloaded
    if @current_resource.is_zip and ! ::File.exists?(unzipped_folderpath) then
      @current_resource.status = 2
      @current_resource.exists = false
    else
      @current_resource.status = 1
      @current_resource.exists = true
    end
  else
    #Mixlib::Log.info("#{@current_resource.name} is older than the source file")
    @current_resource.status = 0
    @current_resource.exists = false
  end


end

action :download do

  path = new_resource.path ? new_resource.path : node["lgfile"]["download_path"]
  protocol = new_resource.protocol ? new_resource.protocol : node["lgfile"]["download_protocol"]
  host = new_resource.host ? new_resource.host : node["lgfile"]["download_host"]
  port = new_resource.port ? new_resource.port : node["lgfile"]["download_port"]
  remote_path = new_resource.remote_path ? new_resource.remote_path : node["lgfile"]["download_remote_path"]
  unzipped_folderpath = String.new
  
  #Contruct local file path + name
  filepath = "#{path}#{"/" unless path.match("/$")}"
  if new_resource.name.match(/\.zip$/)
    is_zip = true 
    unzipped_folderpath = "#{filepath}#{new_resource.name.split(".")[0...-1].join(".")}"
  end
  filepath += "#{new_resource.name}"

  case @current_resource.status
  when 0

    #Contruct local file path + name
    filepath = "#{"/" unless path.match("^/")}#{path}#{"/" unless path.match("/$")}"
    filepath += "#{new_resource.name}"
    
    #contruct URI
    downloaduri = "#{protocol}://#{host}#{":" + port.to_s if port }"
    downloaduri += "#{"/" unless remote_path.match("^/")}#{remote_path}#{"/" unless remote_path.match("/$")}"
    downloaduri += "#{new_resource.name}"
    
    command = "aria2c -R -m 2 --allow-overwrite --conditional-get=true --connect-timeout=10 -d #{path}"
    command += " --check-integrity=true --checksum=md5=#{new_resource.hash}" if new_resource.hash
    
    if new_resource.blocking then
      # If the download should be run in the foreground, download the file, set the status in the node's attr, and update the resource status.
      command += " #{downloaduri}"
      execute command
      unzip_to_folder unzipped_folderpath, filepath if is_zip
      node.set["lgfile"]["files"][new_resource.name] = true
      new_resource.updated_by_last_action(true)
    else
      # If the download is run in the background, check to see if the file is already downloading.  If not, start the download.
      if running? then
        #Mixlib::Log.info "#{new_resource.name} already downloading."
      else
        command += " --on-download-complete=\"#{node["chef_client"]["start_cmd"]}\" -D #{downloaduri}"
        execute command
      end
      new_resource.updated_by_last_action(false)
      #Mixlib::Log.debug("#{new_resource.name} updated by last action: false")
    end
  when 1
    node.set["lgfile"]["files"][new_resource.name] = true
    new_resource.updated_by_last_action(true)
    #Mixlib::Log.debug("#{new_resource.name} updated by last action: true")
  when 2
    unzip_to_folder unzipped_folderpath, filepath
    new_resource.updated_by_last_action(true)
    #Mixlib::Log.debug("#{new_resource.name} updated by last action: true")
  when 3
    new_resource.updated_by_last_action(false)
    #Mixlib::Log.debug("#{new_resource.name} updated by last action: false")
  end
end

action :delete do
  #kill the process if running, remove the file, update the persistence attr to false
  pid = running?
  if pid
    Chef::ShellOut.new("kill #{pid}")
  end
  
  [ "#{new_resource.path}#{new_resource.name}" , "#{new_resource.path}#{new_resource.name}.aria2" ].each do |rmfile|
    file rmfile do
      action :delete
    end
  end
  
  node.set ["lgfile"]["files"][new_resource.name] = false
end