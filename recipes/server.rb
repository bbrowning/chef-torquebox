include_recipe 'java'

torquebox = node[:torquebox]
version = torquebox[:version]
prefix = "/opt/torquebox-#{version}"
current = "/opt/torquebox-current"

ENV['TORQUEBOX_HOME'] = current
ENV['JBOSS_HOME'] = "#{current}/jboss"
ENV['JRUBY_HOME'] = "#{current}/jruby"
ENV['PATH'] = "#{ENV['PATH']}:#{ENV['JRUBY_HOME']}/bin"

package "unzip"
package "upstart"

user "torquebox" do
  comment "torquebox"
  home "/home/torquebox"
  supports :manage_home => true
end

install_from_release('torquebox') do
  release_url   torquebox[:url]
  home_dir      prefix
  action        [:install, :install_binaries]
  version       version
  checksum      torquebox[:checksum]
  not_if{ File.exists?(prefix) }
end

template "/etc/profile.d/torquebox.sh" do
  mode "755"
  source "torquebox.erb"
end

link current do
  to prefix
end

# install upstart & get it running
execute "torquebox-upstart" do
  command "jruby -S rake torquebox:upstart:install"
  creates "/etc/init/torquebox.conf"
  cwd current
  action :run
  environment ({
    'TORQUEBOX_HOME'=> current,
    'JBOSS_HOME'=> "#{current}/jboss",
    'JRUBY_HOME'=> "#{current}jruby",
    'PATH' => "#{ENV['PATH']}:#{current}/jruby/bin"
  })
end

# Allow bind_ip entries like ["cloud", "local_ipv4"]
if torquebox[:bind_ip].is_a?(Array)
  torquebox[:bind_ip] = torquebox[:bind_ip].inject(node) do |hash, key|
    hash[key]
  end
end

# install a customized upstart configuration file
template "/etc/init/torquebox.conf" do
  source "torquebox.conf.erb"
  owner "root"
  group "root"
  mode "644"
  variables :torquebox_dir => current,
            :torquebox_log_dir => torquebox[:log_dir],
            :torquebox_bind_ip => torquebox[:bind_ip]
end

execute "chown torquebox" do
  command "chown -R torquebox:torquebox #{prefix}"
end

service "torquebox" do
  provider Chef::Provider::Service::Upstart
  action [:enable, :start]
end

# otherwise bundler won't work in jruby
gem_package 'jruby-openssl' do
  gem_binary "#{current}/jruby/bin/jgem"
end

#allows use of 'torquebox' command through sudo
cookbook_file "/etc/sudoers.d/torquebox" do
  source 'sudoers'
  owner 'root'
  group 'root'
  mode '0440'
end
