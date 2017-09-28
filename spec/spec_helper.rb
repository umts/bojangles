# frozen_string_literal: true

require 'simplecov'

SimpleCov.start 'rails'
SimpleCov.start do
  add_filter '/config/'
  add_filter '/spec/'
end

require 'json'
require 'timecop'
require 'rspec'
require 'webmock/rspec'
require_relative '../lib/bojangles'

def json_unix_timestamp(*args)
  timestamp = Time.new(*args).to_i
  "/Date(#{timestamp}000-0400)/"
end
