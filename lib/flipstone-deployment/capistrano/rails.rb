Capistrano::Configuration.instance(:must_exist).load do
  #
  # RVM support
  #
  $:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
  require "rvm/capistrano"                  # Load RVM's capistrano plugin.
  set :rvm_ruby_string, '1.9.2'
  set :bundle_flags,    "--binstubs"

  require "bundler/capistrano"
  require "flipstone-deployment/capistrano/rails/rds_recipes"
  require "flipstone-deployment/capistrano/rails/nginx_recipes"
  require "flipstone-deployment/capistrano/rails/unicorn_recipes"
  require "flipstone-deployment/capistrano/rails/fs_recipes"
  require "flipstone-deployment/capistrano/rails/log_recipes"
  require "flipstone-deployment/capistrano/rails/upstart_recipes"
end
