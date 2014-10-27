# -*- mode: ruby -*-
# vi: set ft=ruby :

# Added snap.rb file holds the digital ocean api token values
# so we do not accidently check them into git

require_relative 'snap.rb'
include MyVars

Vagrant.configure("2") do |config|

  # Requires vagrant plugin vagrant-hostmanger to control the /etc/host entries
  # for non production systems
  # https://github.com/smdahlen/vagrant-hostmanager
  config.hostmanager.enabled = false
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  config.vm.define 'development', primary: true do |development|
    development.vm.hostname = "development"
    development.vm.box = "trusty64"
    development.vm.network "forwarded_port", guest: 8080, host: 8080
    development.vm.network "forwarded_port", guest: 8081, host: 8081
    development.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
    development.vm.provision "ansible" do |ansible|
      ansible.playbook = "install_files/ansible-base/securedrop-development.yml"
      ansible.skip_tags = [ "non-development" ]
      ansible.verbose = 'v'
    end
    development.vm.provider "virtualbox" do |v|
      v.name = "development"
      # Running the functional tests with Selenium/Firefox has started causing out-of-memory errors.
      #
      # This started around October 14th and was first observed on the task-queue branch. There are two likely causes:
      # 1. The new job queue backend (redis) is taking up a signiicant amount of memory. According to top, it is not (a couple MB on average).
      # 2. Firefox 33 was released on October 13th: https://www.mozilla.org/en-US/firefox/33.0/releasenotes/ It may require more memory than the previous version did.
      v.memory = 1024
    end
  end

  # The staging hosts are just like production but allow non-tor access
  # for the web interfaces and ssh.
  config.vm.define 'mon-staging', autostart: false do |staging|
    staging.vm.hostname = "mon-staging"
    staging.vm.box = "trusty64"
    staging.vm.network "private_network", ip: "10.0.1.3", virtualbox__intnet: true
    staging.hostmanager.aliases = %w(securedrop-monitor-server-alias)
    staging.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
    staging.vm.synced_folder './', '/vagrant', disabled: true
    staging.vm.provider "virtualbox" do |v|
      v.name = "mon-staging"
    end
  end

  config.vm.define 'app-staging', autostart: false do |staging|
    staging.vm.hostname = "app-staging"
    staging.vm.box = "trusty64"
    staging.vm.network "private_network", ip: "10.0.1.2", virtualbox__intnet: true
    staging.vm.network "forwarded_port", guest: 80, host: 8082
    staging.vm.network "forwarded_port", guest: 8080, host: 8083
    staging.vm.synced_folder './', '/vagrant', disabled: true
    staging.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
    staging.vm.provider "virtualbox" do |v|
      v.name = "app-staging"
      # Running the functional tests with Selenium/Firefox has started causing out-of-memory errors.
      #
      # This started around October 14th and was first observed on the task-queue branch. There are two likely causes:
      # 1. The new job queue backend (redis) is taking up a signiicant amount of memory. According to top, it is not (a couple MB on average).
      # 2. Firefox 33 was released on October 13th: https://www.mozilla.org/en-US/firefox/33.0/releasenotes/ It may require more memory than the previous version did.
      v.memory = 1024
    end
    staging.vm.provision "ansible" do |ansible|
      ansible.playbook = "install_files/ansible-base/securedrop-staging.yml"
      # Other options: 'restart', 'grsec'
      #ansible.skip_tags = [ 'authd' ]
      ansible.verbose = 'v'
      # This will force the staging vm to install the fpf packages from the
      # repo. If you disable this it will look for the packages to be in
      # install_files/ansible-base/ directory. What packages per host is
      # set in that hosts respective install_files/ansible-base/host_vars/
      ansible.skip_tags = [ "install_local_pkgs" ]
      # Taken from the parallel execution tips and tricks
      # https://docs.vagrantup.com/v2/provisioning/ansible.html
      ansible.limit = 'all'
    end
  end

  # The demo hosts are just like production but are virtualized. All access to ssh and
  # the web interfaces is only over tor.
  config.vm.define 'mon-demo', autostart: false do |demo|
    demo.vm.box = "mon"
    demo.vm.box = "trusty64"
    demo.vm.network "private_network", ip: "10.0.1.5", virtualbox__intnet: true
    demo.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
    demo.vm.synced_folder './', '/vagrant', disabled: true
    demo.vm.provider "virtualbox" do |v|
      v.name = "mon"
    end
  end

  config.vm.define 'app-demo', autostart: false do |demo|
    demo.vm.hostname = "app"
    demo.vm.box = "trusty64"
    demo.vm.network "private_network", ip: "10.0.1.4", virtualbox__intnet: true
    demo.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
    demo.vm.synced_folder './', '/vagrant', disabled: true
    demo.vm.provider "virtualbox" do |v|
      v.name = "app"
      # Running the functional tests with Selenium/Firefox has started causing out-of-memory errors.
      #
      # This started around October 14th and was first observed on the task-queue branch. There are two likely causes:
      # 1. The new job queue backend (redis) is taking up a signiicant amount of memory. According to top, it is not (a couple MB on average).
      # 2. Firefox 33 was released on October 13th: https://www.mozilla.org/en-US/firefox/33.0/releasenotes/ It may require more memory than the previous version did.
      v.memory = 1024
    end
    demo.vm.provision "ansible" do |ansible|
      ansible.playbook = "install_files/ansible-base/securedrop-prod.yml"
      ansible.verbose = 'v'
      # the production playbook verifies that staging default values are not
      # used will need to skip the this role to run in Vagrant
      ansible.skip_tags = [ "validate" ]
      # Taken from the parallel execution tips and tricks
      # https://docs.vagrantup.com/v2/provisioning/ansible.html
      ansible.limit = 'all'
    end
  end

  config.vm.define 'app-build', autostart: false do |build|
    build.vm.box = "app-build"
    build.vm.box = "trusty64"
    build.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
    build.vm.provision "ansible" do |ansible|
      ansible.playbook = "install_files/ansible-base/build-deb-pkgs.yml"
      ansible.verbose = 'v'
    end
    build.vm.provider "virtualbox" do |v|
      v.name = "app-build"
    end
  end

  config.vm.define 'mon-build', autostart: false do |build|
    build.vm.box = "mon-build"
    build.vm.box = "trusty64"
    build.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
    build.vm.provision "ansible" do |ansible|
      ansible.playbook = "install_files/ansible-base/build-deb-pkgs.yml"
      ansible.verbose = 'v'
    end
    build.vm.provider "virtualbox" do |v|
      v.name = "mon-build"
    end
  end


  # "Quick Start" config from https://github.com/fgrehm/vagrant-cachier#quick-start
  #if Vagrant.has_plugin?("vagrant-cachier")
  #  config.cache.scope = :box
  #end

  # This is needed for the Snap-ci to provision the digital ocean vps
  config.vm.provider :digital_ocean do |provider, override|
    override.ssh.private_key_path = "/var/snap-ci/repo/id_rsa"
    override.vm.box = 'digital_ocean'
    override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
    provider.token = SNAP_API_TOKEN
    provider.image = 'snapVagrantSSHkey'
    provider.region = 'nyc2'
    provider.size = '512mb'
  end
end
