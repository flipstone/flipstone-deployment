Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    #
    # Unicorn signals per: http://unicorn.bogomips.org/SIGNALS.html
    #
    desc "Create unicorn configuration file"
    task :unicorn_config, :roles => :app do
      template = File.read(File.join(File.dirname(__FILE__), "unicorn.conf.erb"))
      buffer   = ERB.new(template).result(binding)
      put buffer, "#{shared_path}/system/unicorn.conf"
    end

    task :start, :roles => :app do
      sudo "start #{application}"
    end

    task :stop, :roles => :app do
      # returning true on stop in the event this app isn't actually running 
      # todo figure out how to test results of `status #{application}`
      run "test -f /etc/init.d/#{application} && sudo stop #{application}; true"
      run "test -f #{shared_path}/pids/unicorn.pid && kill -TERM `cat #{shared_path}/pids/unicorn.pid`; true"
    end

    task :restart, :roles => :app do
      stop
      start
    end

    task :reload, :roles => :app do
      run "test -f #{shared_path}/pids/unicorn.pid && kill -HUP `cat #{shared_path}/pids/unicorn.pid`"
    end
  end

  #
  # Deploy callbacks
  #
  before 'deploy:start', "deploy:unicorn_config"
  before 'deploy:migrations', 'deploy:web:disable'
  after 'deploy:migrations', 'deploy:web:enable'
  after 'deploy:migrations', 'deploy:cleanup'
  
end
