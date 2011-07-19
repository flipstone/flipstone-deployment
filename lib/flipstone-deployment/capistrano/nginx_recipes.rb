Capistrano::Configuration.instance(:must_exist).load do
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
end
