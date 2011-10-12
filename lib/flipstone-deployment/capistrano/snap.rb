Capistrano::Configuration.instance(:must_exist).load do
  require "flipstone-deployment/capistrano/snap/deploy.rb"
end
