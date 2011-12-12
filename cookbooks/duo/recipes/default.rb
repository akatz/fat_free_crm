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
  owner 'root'
  group 'root'
  mode 0644
  source 'pam_duo.conf'
  backup 0
end

execute "/usr/sbin/login_duo" do
  command "/usr/sbin/login_duo"
  user 'deploy'
end

execute "add pam to config" do
  command "sed '/auth.*unix/a auth\t\trequired\tpam_duo.so' /etc/pam.d/system-auth"
end
