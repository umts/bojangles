require 'active_record'
require 'json'
require 'mysql2'

DATABASE_SETTINGS = JSON.parse(File.read 'config/database.json')

ActiveRecord::Base.establish_connection(DATABASE_SETTINGS)

unless ActiveRecord::Base.connection.tables.any?
  ActiveRecord::Schema.define do
    create_table :departures, force: true do |t|
      t.datetime :sdt
      t.integer :route_id
      t.integer :stop_id
    end

    create_table :routes, force: true do |t|
      t.string :number
      t.string :avail_id
    end

    create_table :stops, force: true do |t|
      t.string :name
      t.integer :hastus_id
      t.boolean :active, default: true
    end
  end
end

