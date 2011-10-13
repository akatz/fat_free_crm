#
# Cookbook Name:: packages
# Recipe:: default
#

remote_file "/engineyard/portage/engineyard/www-servers/nginx/nginx-0.8.55-r2.ebuild"  do 
  owner "root"
  group "root"
  mode 0644 
  source "nginx-0.8.55.r2.ebuild"
end 

execute "ebuild /engineyard/portage/engineyard/www-servers/nginx/nginx-0.8.55-r2.ebuild manifest"

execute "emerge --sync"

execute "upgrade nginx" do
  command "emerge -1n nginx"
  user "root"
  not_if "emerge --search nginx |grep installed | awk '{print $4}'" == "emerge --search nginx |grep available | awk '{print $4}'"
end
