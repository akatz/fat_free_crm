# 
# CookBook Name:: duo
# Recipe:: default
#
directory "/mnt/tmp/duo" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

remote_file "/mnt/tmp/duo/duo_unix-1.7.tar.gz" do
  source "https://github.com/downloads/duosecurity/duo_unix/duo_unix-1.7.tar.gz"
  owner "root"
  group "root"
  mode 0755
  backup 0
end

execute "untar duo" do
  cwd "/mnt/tmp/duo"
  command "tar zxf duo_unix-1.7.tar.gz"
end

execute "configure duo" do
  cwd "/mnt/tmp/duo/duo_unix-1.7"
  command "./configure --with-pam --prefix=/usr"
end

execute "make duo" do
  cwd "/mnt/tmp/duo/duo_unix-1.7"
  command "make"
end

execute "install duo" do
  cwd "/mnt/tmp/duo/duo_unix-1.7"
  command "make install"
end

directory "/mnt/tmp/duo" do
  action :delete
  recursive true
end

remote_file '/etc/duo/pam_duo.conf' do
  owner 'deploy'
  group 'deploy'
  mode 0600
  source 'pam_duo.conf'
  backup 0
end

remote_file '/etc/duo/login_duo.conf' do
  owner 'deploy'
  group 'deploy'
  mode 0600
  source 'login_duo.conf'
  backup 0
end

execute "chown deploy:deploy /usr/sbin/login_duo"

#execute "bash -c '/usr/sbin/login_duo > /tmp/link'" do
#  cwd '/home/deploy'
#  user 'deploy'
#  returns 1
#end


execute "add duo to sshd_config" do
  command "sed -i '/UseDNS/a ForceCommand /usr/sbin/login_duo' /etc/ssh/sshd_config"
  not_if "grep login_duo /etc/ssh/sshd_config"
end

execute "restart sshd" do
  command "/etc/init.d/sshd restart"
end
