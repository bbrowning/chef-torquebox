include_recipe 'java'
include_recipe 'runit'

torquebox = node[:torquebox]
version = torquebox[:version]
prefix = "/opt/torquebox-#{version}"
current = torquebox[:torquebox_dir]

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

# Allow bind_ip entries like ["cloud", "local_ipv4"]
if torquebox[:bind_ip].is_a?(Array)
  torquebox[:bind_ip] = torquebox[:bind_ip].inject(node) do |hash, key|
    hash[key]
  end
end

execute "chown torquebox" do
  command "chown -R torquebox:torquebox /usr/local/share/torquebox-#{version}"
end

runit_service "torquebox" do
  options   torquebox
  run_state torquebox[:run_state]
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
