Capistrano::Configuration.instance(:must_exist).load do
  #
  # RVM support
  #
  $:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
  require "rvm/capistrano"                  # Load RVM's capistrano plugin.
  set :rvm_ruby_string, '1.9.2'
  set :bundle_flags,    "--binstubs"
  set :rvm_type, :system

  require "bundler/capistrano"
  require "flipstone-deployment/capistrano/ruby/appserver_recipes"
  require "flipstone-deployment/capistrano/ruby/fs_recipes"
  require "flipstone-deployment/capistrano/ruby/log_recipes"
  require "flipstone-deployment/capistrano/ruby/upstart_recipes"
end
