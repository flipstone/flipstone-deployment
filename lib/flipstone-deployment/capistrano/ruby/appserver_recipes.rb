Capistrano::Configuration.instance(:must_exist).load do
  namespace :appserver do
    task :appserver_namespace do
      send("appserver_#{appserver_name}")
    end

    desc "Create wrapper for executing the app"
    task :wrapper do
      appserver_namespace.wrapper
    end

    desc "Executable to be put in upstart configuration"
    task :path do
      appserver_namespace.path
    end

    desc "Executable arguments to be put in upstart configuration"
    task :args do
      appserver_namespace.args
    end

    desc "Pid file to be put in upstart configuration"
    task :pidfile do
      appserver_namespace.pidfile
    end

    desc "Create appserver configuration file"
    task :config, :roles => :app do
      appserver_namespace.config
    end

    desc "Port to put into nginx config file for upstream appserver"
    task :port do
      appserver_namespace.port
    end
  end

  namespace :deploy do
    task :start, :roles => :app do
      sudo "start #{application}"
    end

    task :stop, :roles => :app do
      # returning true on stop in the event this app isn't actually running
      # todo figure out how to test results of `status #{application}`
      run "test -f /etc/init.d/#{application} && sudo stop #{application}; true"
      run "test -f #{appserver.pidfile} && kill -TERM `cat #{appserver.pidfile}`; true"
    end

    task :restart, :roles => :app do
      stop
      start
    end

    task :reload, :roles => :app do
      run "test -f #{appserver.pidfile} && kill -HUP `#{appserver.pidfile}`"
    end
  end

  #
  # Deploy callbacks
  #
  before 'upstart:install_application', "appserver:wrapper"
  before 'upstart:install_application', "appserver:config"
  before 'deploy:migrations', 'deploy:web:disable'
  after 'deploy:migrations', 'deploy:web:enable'
  after 'deploy:migrations', 'deploy:cleanup'
  after 'deploy', 'deploy:cleanup'
end
