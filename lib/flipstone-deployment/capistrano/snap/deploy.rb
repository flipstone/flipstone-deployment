Capistrano::Configuration.instance(:must_exist).load do
  desc <<-DESC
    Push the deploy key and create the GIT_SSH script to use it
  DESC
  task :install_deploy_keys, :roles => :app do
    deploy_key_path = "#{deploy_to}/id_deploy"
    run "rm -f #{deploy_key_path}"
    top.upload("resources/config/deploy_key", deploy_key_path, :via => :scp)
    run "chmod 400 #{deploy_key_path}"

    wrapper_path = "#{deploy_to}/git_ssh.sh"
    gitssh = "/usr/bin/env ssh -o StrictHostKeyChecking=no -i #{deploy_key_path} $1 $2\n"
    put gitssh, wrapper_path
    run "chmod 755 #{wrapper_path}"
    run "export GIT_SSH=#{wrapper_path}"
  end

  before 'deploy:update_code', 'install_deploy_keys'
  set(:cabal_dev) { "cabal-dev --sandbox=#{shared_path}/cabal-dev" }

  # this tells capistrano what to do when you deploy
  namespace :deploy do
    desc <<-DESC
    A macro-task that updates the code and fixes the symlink.
    DESC
    task :default do
      transaction do
        update_code
        build.executable
        symlink
        restart
      end
    end

    task :symlink_log do
      run "ln -sf #{shared_path}/log #{current_path}/log"
    end
    after 'deploy:symlink', 'deploy:symlink_log'

    task :update_code, :except => { :no_release => true } do
      on_rollback { run "rm -rf #{release_path}; true" }
      strategy.deploy!
    end

    after :deploy, 'deploy:cleanup'

    task :restart do
      stop
      start
    end

    task :stop do
      # returning true on stop in the event this app isn't actually running 
      # todo figure out how to test results of `status #{application}`
      run "test -f /etc/init.d/#{application} && sudo stop #{application}; true"
    end

    task :start do
      sudo "start #{application}"
    end
  end

  namespace :build do
    desc "Build the application executable"
    task :executable do
      run "cd #{release_path} && #{cabal_dev} update && #{cabal_dev} install --only-dependencies && #{cabal_dev} configure && #{cabal_dev} build"
    end
  end

  namespace :upstart do
   desc <<-DESC
     Push upstart config to /etc/init and install to /etc/init.d
   DESC
   task :install_application, :roles => :app do
     upstart_file_path = "#{shared_path}/system/upstart.conf"
     template = File.read(File.join(File.dirname(__FILE__), "upstartjob.conf.erb"))
     buffer   = ERB.new(template).result(binding)
     put buffer, upstart_file_path
     sudo "ln -sf #{upstart_file_path} /etc/init/#{application}.conf"
     sudo "ln -sf /lib/init/upstart-job /etc/init.d/#{application}"
   end

   task :reload_configuration, :roles => :app do
     sudo "initctl reload-configuration"
   end
  end

  before 'deploy:stop', 'deploy:web:disable'
  after 'deploy:start', 'deploy:web:enable'
  before 'deploy:start', 'upstart:install_application'
  after 'upstart:install_application', 'upstart:reload_configuration'

  namespace :nginx do
    desc "Create nginx configuration file"
    task :config, :roles => :app do
      template = File.read(File.join(File.dirname(__FILE__), "nginx.conf.erb"))
      buffer   = ERB.new(template).result(binding)
      put buffer, "#{shared_path}/system/nginx.conf"
    end

    desc "Enable nginx site from available configuration"
    task :site_enable, :roles => :app do
      sudo "nxensite #{application} #{application} #{shared_path}/system/nginx.conf"
    end

    desc "Disable nginx site from available configuration"
    task :site_disable, :roles => :app do
      sudo "nxdissite #{application}"
    end

    desc "Reload nginx configurations"
    task :reload, :roles => :app do
      sudo "nginx -s reload"
    end

    desc "Generate password file (requires attribute nginx_cfg[:ht_user] and nginx_cfg[:ht_passwd])"
    task :generate_passfile, :roles => :app do
      run "htpasswd.py -c -b #{shared_path}/system/passfile #{nginx_cfg[:ht_user]} #{nginx_cfg[:ht_passwd]}"
    end
  end

  after :deploy do
    if nginx_cfg[:ht_user] && nginx_cfg[:ht_passwd]
      nginx.generate_passfile
    end
    nginx.config
    nginx.site_enable
    nginx.reload
  end
end

