Capistrano::Configuration.instance(:must_exist).load do
  namespace :rds do
    set :cfg, {}

    set :mysqlcmd, lambda { "mysql -h #{rds_cfg[:host]} -u #{rds_cfg[:master_user]} --password=#{rds_cfg[:master_pwd]} -P #{rds_cfg[:port]}" }
    set :mysqldumpcmd, lambda { "mysqldump -h #{rds_cfg[:host]} -u #{rds_cfg[:master_user]} --password=#{rds_cfg[:master_pwd]}" }
    set :prod_clone_source, "production" unless exists?(:prod_clone_source)

    desc <<-DESC
      Create the MySQL database. Assumes there is no MySQL root \
      password. To create a MySQL root password create a task that's run \
      after this task using an after hook.
    DESC
    task :create, :roles => :app do
      on_rollback { drop }
      load_config

      run %{#{mysqlcmd} -e "create database if not exists #{cfg[:db_name]};"}
      run %{#{mysqlcmd}  -e "grant all on #{cfg[:db_name]}.* to '#{cfg[:db_user]}'@'%' identified by '#{cfg[:db_password]}';"}
      run %{#{mysqlcmd}  -e "grant reload on *.* to '#{cfg[:db_user]}'@'%' identified by '#{cfg[:db_password]}';"}
    end

    desc <<-DESC
      Drop the MySQL database. Assumes there is no MySQL root \
      password. If there is a MySQL root password, create a task that removes \
      it and run that task before this one using a before hook.
    DESC
    task :drop, :roles => :app do
      load_config
      run %{#{mysqlcmd}  -e "drop database if exists #{cfg[:db_name]};"}
    end

    desc <<-DESC
      db:drop and db:create.
    DESC
    task :recreate, :roles => :db do
      drop
      create
    end

    desc <<-DESC
      db:clone_prod makes the target schema a copy of the production schema. (or whatever env is specified by -S prod_clone_source=<dbconfig>
    DESC
    task :clone_prod, :roles => :db do
      load_config

      # drop all tables
      run %{#{mysqldumpcmd} --add-drop-table --no-data #{cfg[:db_name]} | grep -E '^DROP|FOREIGN_KEY_CHECKS' | #{mysqlcmd} #{cfg[:db_name]}}

      # Doing this manually is not DRY but also avoids putting the production environment configuration too-conveniently close at hand.
      prod_config = YAML::load(ERB.new(File.read("config/database.yml")).result)[prod_clone_source]

      cfg[:prod_name] = prod_config['database']
      cfg[:prod_user] = prod_config['username'] || prod_config['user'] 
      cfg[:prod_password] = prod_config['password']
      cfg[:prod_host] = prod_config['host']
      cfg[:prod_socket] = prod_config['socket']

      if (cfg[:prod_host].nil? || cfg[:prod_host].empty?) && (cfg[:prod_socket].nil? || cfg[:prod_socket].empty?)
          raise "ERROR: missing database config. Make sure database.yml contains a 'production' section with either 'host: hostname' or 'socket: /var/run/mysqld/mysqld.sock'."
      end

      [cfg[:prod_name], cfg[:prod_user]].each do |s|
       if s.nil? || s.empty?
         raise "ERROR: missing database config. Make sure database.yml contains a 'production' section with a database name, user, and password."
       elsif s.match(/['"]/)
         raise "ERROR: production database config string '#{s}' contains quotes."
       end
      end

      run %{mysqldump #{cfg[:prod_name]} -h #{cfg[:prod_host]} -u #{cfg[:prod_user]} --password=#{cfg[:prod_password]} | #{mysqlcmd} #{cfg[:db_name]}}
    end

    desc <<-DESC
      db:clone_snapshot makes the target schema a copy of the snapshot schema.
    DESC
    task :clone_snapshot, :roles => :db do
      load_config

      # drop all tables
      run %{#{mysqldumpcmd} --add-drop-table --no-data #{cfg[:db_name]} | grep -E '^DROP|FOREIGN_KEY_CHECKS' | #{mysqlcmd} #{cfg[:db_name]}}

      snapshot_config = YAML::load(ERB.new(File.read("config/database.yml")).result)["snapshot"]

      cfg[:snapshot_name] = snapshot_config['database']
      cfg[:snapshot_user] = snapshot_config['username'] || snapshot_config['user']
      cfg[:snapshot_password] = snapshot_config['password']
      cfg[:snapshot_host] = snapshot_config['host']
      cfg[:snapshot_socket] = snapshot_config['socket']

      if (cfg[:snapshot_host].nil? || cfg[:snapshot_host].empty?) && (cfg[:snapshot_socket].nil? || cfg[:snapshot_socket].empty?)
          raise "ERROR: missing database config. Make sure database.yml contains a 'snapshot' section with either 'host: hostname' or 'socket: /var/run/mysqld/mysqld.sock'."
      end

      [cfg[:snapshot_name], cfg[:snapshot_user]].each do |s|
       if s.nil? || s.empty?
         raise "ERROR: missing database config. Make sure database.yml contains a 'snapshot' section with a database name, user, and password."
       elsif s.match(/['"]/)
         raise "ERROR: snapshot database config string '#{s}' contains quotes."
       end
      end

      run %{mysqldump #{cfg[:snapshot_name]} -h #{cfg[:snapshot_host]} -u #{cfg[:snapshot_user]} --password=#{cfg[:snapshot_password]} | #{mysqlcmd} #{cfg[:db_name]}}
    end

    desc <<-DESC
      [internal] Load configuration info for the database from
      config/database.yml, and start mysql (it must be running
      in order to interact with it).
    DESC
    task :load_config do
        db_config = YAML::load(ERB.new(File.read("config/database.yml")).result)[rails_env.to_s]
        cfg[:db_name] = db_config['database']
        cfg[:db_user] = db_config['username'] || db_config['user']
        cfg[:db_password] = db_config['password']
        cfg[:db_host] = db_config['host']
        cfg[:db_socket] = db_config['socket']

        if (cfg[:db_host].nil? || cfg[:db_host].empty?) && (cfg[:db_socket].nil? || cfg[:db_socket].empty?)
            raise "ERROR: missing database config. Make sure database.yml contains a '#{rails_env}' section with either 'host: hostname' or 'socket: /var/run/mysqld/mysqld.sock'."
        end

         [cfg[:db_name], cfg[:db_user]].each do |s|
          if s.nil? || s.empty?
            raise "ERROR: missing database config. Make sure database.yml contains a '#{rails_env}' section with a database name, user, and password."
          elsif s.match(/['"]/)
            raise "ERROR: database config string '#{s}' contains quotes."
          end
        end

    end
  end
end
