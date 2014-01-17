maintainer       "Peter Bell"
maintainer_email "bellpeterm@gmail.com"
license          "Apache 2.0"
description      "Uses aria2 to download large files"
long_description "Uses aria2 to download large files, able to resume interrupted downloads and download in the background."
version          "2.0.0"
depends          "chef-client", ">= 2.2.2"
depends          "apt"
depends          "homebrew"
depends			 "chocolatey"

%w{ ubuntu mac_os_x mac_os_x_server windows }.each do |os|
  supports os
end