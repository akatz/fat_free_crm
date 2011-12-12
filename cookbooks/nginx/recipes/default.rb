# 
# CookBook Name:: nginx
# Recipe:: default
#
if ['solo','app_master', 'app'].include?(node[:instance_role])

  execute "reload-nginx" do
    command "/etc/init.d/nginx reload"
    action :nothing
  end

  template do "/etc/nginx/servers/empty_app/custom.locations.conf"
    source "custom.conf.erb"
    notifies :run, resources(:execute => "reload-nginx")
  end


  execute "emerge --sync"

  enable_package "www-servers/nginx" do
    version "0.8.55-r3"
  end

  package_use "www-servers/nginx" do
   flags "modzip"
  end

  bash "upgrade nginx" do
    code "emerge -1n nginx"
    user "root"
    not_if "emerge --search nginx |grep installed | awk '{print $4}'" == "emerge --search nginx |grep available | awk '{print $4}'"
  end

  execute "upgrade nginx with init" do
    command "/etc/init.d/nginx upgrade"
  end

end

