# frozen_string_literal: true

lock '3.9.0'

set :application, 'bojangles'
set :repo_url, 'https://github.com/umts/bojangles.git'
set :branch, :master
set :deploy_to, "/srv/#{fetch :application}"
set :keep_releases, 5

set :linked_files, fetch(:linked_files, []).push(
  'cached_departures.json',
  'cached_stops.json',
  'error_messages.json',
  'config/config.json',
  'config/database.json',
  'route_mappings.json'
)

set :linked_dirs, fetch(:linked_dirs, []).push(
  'gtfs',
  'log'
)
