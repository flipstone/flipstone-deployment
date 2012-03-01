Capistrano::Configuration.instance(:must_exist).load do
  set(:zbatery_stderr_path) { "#{shared_path}/log/zbatery.err.log" }
  set(:zbatery_stdout_path) { "#{shared_path}/log/zbatery.log" }

  namespace :appserver_zbatery do
    desc "Create wrapper for executing the app"
    task :wrapper do
      sudo "rvm wrapper 1.9.2 #{application} #{current_path}/bin/zbatery"
    end

    desc "Executable to be put in upstart configuration"
    task :path do
      "/usr/local/rvm/bin/#{application}_zbatery"
    end

    desc "Executable arguments to be put in upstart configuration"
    task :args do
      "-E #{rails_env} -c #{shared_path}/system/zbatery.conf"
    end

    desc "Pid file to be put in upstart configuration"
    task :pidfile do
      "#{shared_path}/pids/zbatery.pid"
    end

    #
    # Unicorn signals per: http://unicorn.bogomips.org/SIGNALS.html
    #
    desc "Create zbatery configuration file"
    task :config, :roles => :app do
      template = File.read(File.join(File.dirname(__FILE__), "zbatery.conf.erb"))
      buffer   = ERB.new(template).result(binding)
      put buffer, "#{shared_path}/system/zbatery.conf"
    end

    desc "Port to put into nginx config file for upstream appserver"
    task :port do
      zbatery[:port]
    end
  end
end


