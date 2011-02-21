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
      run "cd #{current_path} && bundle exec unicorn --daemonize -E #{rails_env} -c #{shared_path}/system/unicorn.conf"
    end

    task :stop, :roles => :app do
      run "test -f #{shared_path}/pids/unicorn.pid && kill -QUIT `cat #{shared_path}/pids/unicorn.pid` && sleep 7; echo 'succeed'"
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
  before 'deploy:stop', 'deploy:web:disable'
  after 'deploy:start', 'deploy:web:enable'
  after 'deploy:migrations', 'deploy:cleanup'
  
end
