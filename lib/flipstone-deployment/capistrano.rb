Capistrano::Configuration.instance(:must_exist).load do
  #
  # RVM support
  #
  $:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
  require "rvm/capistrano"                  # Load RVM's capistrano plugin.
  set :rvm_ruby_string, '1.9.2'

  require "bundler/capistrano"
  require "flipstone-deployment/capistrano/rds_recipes"
  require "flipstone-deployment/capistrano/nginx_recipes"
  require "flipstone-deployment/capistrano/unicorn_recipes"
  require "flipstone-deployment/capistrano/fs_recipes"
  require "flipstone-deployment/capistrano/log_recipes"
  require "flipstone-deployment/capistrano/upstart_recipes"
end
