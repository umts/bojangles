# frozen_string_literal: true

lock '3.14.1'

set :application, 'bojangles'
set :repo_url, 'https://github.com/umts/bojangles.git'
set :branch, :master
set :deploy_to, "/srv/#{fetch :application}"
set :keep_releases, 5

append :linked_files,
       'cached_departures.json',
       'cached_stops.json',
       'error_messages.json',
       'config/config.json',
       'config/database.json',
       'route_mappings.json'

append :linked_dirs,
       '.bundle',
       'log'
