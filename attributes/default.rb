
default[:torquebox][:version] = "2.0.0"
default[:torquebox][:url] = "http://torquebox.org/release/org/torquebox/torquebox-dist/#{node[:torquebox][:version]}/torquebox-dist-#{node[:torquebox][:version]}-bin.zip"
default[:torquebox][:checksum] = "e52d25b08e169494ffc240ed65d52648"
default[:torquebox][:jruby][:opts] = "--1.8"
default[:torquebox][:backstage_gitrepo] = "git://github.com/torquebox/backstage.git"
default[:torquebox][:backstage_home] = "/var/www/backstage"
