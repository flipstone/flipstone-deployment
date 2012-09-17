Capistrano::Configuration.instance(:must_exist).load do
  require "flipstone-deployment/capistrano/node/deploy.rb"
  require "flipstone-deployment/capistrano/ruby/log_recipes.rb"
end
