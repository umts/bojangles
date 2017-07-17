lock "3.8.1"

set :application, "bojangles"
set :repo_url, "git@github.com:umts/bojangles.git"
set :branch, :master
set :deploy_to, "/srv/#{fetch :application}"
set :scm, :git
set :keep_releases, 5

set :whenever_command, %i(sudo bundle exec whenever)
