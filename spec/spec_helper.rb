# frozen_string_literal: true
require 'simplecov'

SimpleCov.start 'rails'
SimpleCov.start do
  add_filter '/config/'
  add_filter '/spec/'
end

require 'rspec'
require 'webmock/rspec'
require_relative '../lib/bojangles'

