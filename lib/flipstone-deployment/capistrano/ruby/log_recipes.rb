Capistrano::Configuration.instance(:must_exist).load do
  namespace :logrotate do
    desc "Create application logrotate configuration file"
    task :config, :roles => :app do
      template = File.read(File.join(File.dirname(__FILE__), "logrotate.erb"))
      buffer   = ERB.new(template).result(binding)
      logrotate_config_path = "#{shared_path}/system/logrotated.conf"
      put buffer, logrotate_config_path
      sudo "ln -sf  #{logrotate_config_path} /etc/logrotate.d/#{application}"
    end
  end
  #
  # Deploy callbacks
  #
  after 'deploy:start', "logrotate:config"

end

