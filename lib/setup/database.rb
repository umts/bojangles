require 'active_record'
require 'json'
require 'mysql2'

DATABASE_SETTINGS = JSON.parse(File.read 'config/database.json')

ActiveRecord::Base.establish_connection(DATABASE_SETTINGS)

unless ActiveRecord::Base.connection.tables.any? && !ENV['REINITIALIZE']
  ActiveRecord::Schema.define do
    create_table :departures, force: true do |t|
      t.integer :sdt
      t.integer :trip_id
      t.integer :stop_id
    end

    create_table :issues, force: true do |t|
      t.integer :route_id
      t.integer :stop_id
      t.string :headsign
      t.string :issue_type
      t.integer :github_number
      t.boolean :open
    end

    create_table :routes, force: true do |t|
      t.string :number
      t.string :hastus_id
      t.string :avail_id
    end

    create_table :service_exceptions, force: true do |t|
      t.integer :service_id
      t.string :exception_type
      t.date :date
    end

    create_table :services, force: true do |t|
      t.string :hastus_id
      t.date :start_date
      t.date :end_date
      t.text :weekdays
    end

    create_table :stops, force: true do |t|
      t.string :name
      t.integer :hastus_id
      t.boolean :active, default: true
    end

    create_table :trips, force: true do |t|
      t.integer :route_id
      t.integer :service_id
      t.string :hastus_id
      t.string :headsign
    end
  end
end

