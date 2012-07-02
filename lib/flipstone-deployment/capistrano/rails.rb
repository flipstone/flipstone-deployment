require "flipstone-deployment/capistrano/ruby"

Capistrano::Configuration.instance(:must_exist).load do
  require "flipstone-deployment/capistrano/rails/rds_recipes"
  require "flipstone-deployment/capistrano/rails/nginx_recipes"
  require "flipstone-deployment/capistrano/rails/rainbows_recipes"
  require "flipstone-deployment/capistrano/rails/unicorn_recipes"
  require "flipstone-deployment/capistrano/rails/zbatery_recipes"

  # default to using unicorn
  set :appserver_name, :unicorn
end
