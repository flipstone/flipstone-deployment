Capistrano::Configuration.instance(:must_exist).load do
  #
  # Basic flipstone utility tasks
  #
  desc <<-DESC
    Push the deploy key and create the GIT_SSH script to use it
  DESC
  task :install_deploy_keys, :roles => :app do
    deploy_key_path = "#{deploy_to}/id_deploy"
    run "rm -f #{deploy_key_path}"
    top.upload("config/deploy/deploy_key", deploy_key_path, :via => :scp)
    run "chmod 400 #{deploy_key_path}"
    
    wrapper_path = "#{deploy_to}/git_ssh.sh"
    gitssh = "/usr/bin/env ssh -o StrictHostKeyChecking=no -i #{deploy_key_path} $1 $2\n"
    put gitssh, wrapper_path
    run "chmod 755 #{wrapper_path}"
    run "export GIT_SSH=#{wrapper_path}"
  end

  desc <<-DESC
    Prepares an environment to receive deployments.  If the environment runs its own
    DB server, the appropriate database will need to be created.
    [For safety, please run rds:create mnually]
  DESC
  task :prepare_host do
    deploy.setup
    install_deploy_keys
    deploy.update
    logrotate.config
    deploy.unicorn_config
    nginx.config
    nginx.site_enable
    nginx.reload
  end

  set :deployment_safeword, 'set deployment_safeword to change this value'
  task :sanity_check do
    puts " **\n **"
    puts (" ** PRODUCTION TARGET SANITY CHECK ** ")
    puts " **\n **"

    safeword = Capistrano::CLI.ui.ask(" ** Please confirm with safeword '#{deployment_safeword}' or [Enter] to abort:")
    unless safeword == deployment_safeword
      puts (" ** Safeword check failed.  Aborting.")
      exit! -1
    end
  end
end
