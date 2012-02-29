Capistrano::Configuration.instance(:must_exist).load do
  set(:upstart_conf_file) { File.join(File.dirname(__FILE__), "upstartjob.conf.erb") }

  namespace :upstart do
    desc <<-DESC
      Push upstart config to /etc/init and install to /etc/init.d
    DESC
    task :install_application, :roles => :app do
      upstart_file_path = "#{shared_path}/system/upstart.conf"
      template = File.read upstart_conf_file
      buffer   = ERB.new(template).result(binding)
      put buffer, upstart_file_path
      sudo "ln -sf #{upstart_file_path} /etc/init/#{application}.conf"
      sudo "ln -sf /lib/init/upstart-job /etc/init.d/#{application}"
    end

    task :reload_configuration, :roles => :app do
      sudo "initctl reload-configuration"
    end
  end

  before 'deploy:start', 'upstart:install_application'
  after 'upstart:install_application', 'upstart:reload_configuration'
end

