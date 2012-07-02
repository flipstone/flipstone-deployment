Capistrano::Configuration.instance(:must_exist).load do
  set(:rainbows_stderr_path) { "#{shared_path}/log/rainbows.err.log" }
  set(:rainbows_stdout_path) { "#{shared_path}/log/rainbows.log" }

  namespace :appserver_rainbows do
    desc "Create wrapper for executing the app"
    task :wrapper do
      sudo "rvm wrapper 1.9.2 #{application} #{current_path}/bin/rainbows"
    end

    desc "Executable to be put in upstart configuration"
    task :path do
      "/usr/local/rvm/bin/#{application}_rainbows"
    end

    desc "Executable arguments to be put in upstart configuration"
    task :args do
      "-E #{rails_env} -c #{shared_path}/system/rainbows.conf"
    end

    desc "Pid file to be put in upstart configuration"
    task :pidfile do
      #intentionally left to facilitate switchover
      "#{shared_path}/pids/unicorn.pid"
    end

    #
    # Unicorn signals per: http://unicorn.bogomips.org/SIGNALS.html
    #
    desc "Create rainbows configuration file"
    task :config, :roles => :app do
      template = File.read(File.join(File.dirname(__FILE__), "rainbows.conf.erb"))
      buffer   = ERB.new(template).result(binding)
      put buffer, "#{shared_path}/system/rainbows.conf"
    end

    desc "Port to put into nginx config file for upstream appserver"
    task :port do
      rainbows[:port]
    end
  end
end


