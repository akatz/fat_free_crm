#
# Cookbook Name:: packages
# Recipe:: default
#

if ['solo','app','app_master'].include?(node[:instance_role])
  remote_file "/engineyard/portage/engineyard/www-servers/nginx/nginx-0.8.55-r2.ebuild"  do 
    owner "root"
    group "root"
    mode 0644 
    source "nginx-0.8.55-r2.ebuild"
  end 

  execute "ebuild nginx-0.8.55-r2.ebuild digest" do
    cwd "/engineyard/portage/engineyard/www-servers/nginx/"
  end

  execute "emerge --sync"

  execute "upgrade nginx" do
    command "emerge -1n nginx"
    user "root"
    not_if "emerge --search nginx |grep installed | awk '{print $4}'" == "emerge --search nginx |grep available | awk '{print $4}'"
  end
end
