# frozen_string_literal: true

require 'active_record'
require 'json'

DATABASE_SETTINGS = JSON.parse File.read('config/database.json')
require DATABASE_SETTINGS.fetch('adapter')

ActiveRecord::Base.establish_connection(DATABASE_SETTINGS)

if ActiveRecord::Base.connection.tables.none? || ENV['REINITIALIZE']
  ActiveRecord::Schema.define do
    create_table :departures, force: true do |t|
      t.integer :sdt
      t.integer :stop_id
      t.integer :trip_id
    end

    create_table :issues, force: true do |t|
      t.text    :alternatives
      t.integer :github_number
      t.string  :headsign
      t.string  :issue_type
      t.boolean :open
      t.integer :route_id
      t.integer :stop_id
      t.integer :sdt
      t.boolean :visible
    end

    create_table :routes, force: true do |t|
      t.string  :avail_id
      t.string  :hastus_id
      t.string  :number
    end

    create_table :service_exceptions, force: true do |t|
      t.date    :date
      t.string  :exception_type
      t.integer :service_id
    end

    create_table :services, force: true do |t|
      t.date    :end_date
      t.string  :hastus_id
      t.date    :start_date
      t.text    :weekdays
    end

    create_table :stops, force: true do |t|
      t.boolean :active, default: true
      t.integer :hastus_id
      t.string  :name
    end

    create_table :trips, force: true do |t|
      t.string  :hastus_id
      t.string  :headsign
      t.integer :route_id
      t.integer :service_id
    end
  end
end
