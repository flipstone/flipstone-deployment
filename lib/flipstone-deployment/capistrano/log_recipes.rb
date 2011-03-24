Capistrano::Configuration.instance(:must_exist).load do
  namespace :logrotate do
    desc "Create application logrotate configuration file"
    task :config, :roles => :app do
      template = File.read(File.join(File.dirname(__FILE__), "logrotated.erb"))
      buffer   = ERB.new(template).result(binding)
      put buffer, "/etc/logrotate.d/#{application}"
    end
  end
end