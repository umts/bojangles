# frozen_string_literal: true

source 'https://rubygems.org'
ruby IO.read(File.expand_path('.ruby-version', __dir__)).strip

gem 'activerecord', '~> 5.1'
gem 'activesupport', '~> 5.1'
gem 'mysql2', '~> 0.4'
gem 'octokit', '~> 4.7'
gem 'rake', '~> 12.0'
gem 'whenever', '~> 0.9'
gem 'zipruby', '~> 0.3'

group :development, :test do
  gem 'capistrano', '3.9.0', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-pending', require: false
  gem 'fancy_irb'
  gem 'pry-byebug', require: false
  gem 'rspec'
  gem 'rubocop'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'webmock'
  gem 'wirb'
end
