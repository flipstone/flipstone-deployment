Capistrano::Configuration.instance(:must_exist).load do
  require "flipstone-deployment/capistrano/node/deploy.rb"
end
