# frozen_string_literal: true
require 'spec_helper'
include DepartureComparator
include GtfsParser

describe DepartureComparator do
  before :each do
    @messages = ['error']
    @statuses = { feed_down: false, missing_routes: [], incorrect_times: [] }
    @all_messages = []
    @route_number = '45'
    @headsign = 'UMass'
    @gtfs_time = Time.now
    @type = 'EVE'
    @avail_time = Time.now + 2.minutes
  end
  describe 'email_format' do
    context 'with time parameter' do
      it 'formats the time' do
        time = Time.now
        expect(email_format(time)).to eql time.strftime '%I:%M:%S %p'
      end
    end
  end
  describe 'report_feed_down' do
    context 'with previous messages' do
      it 'adds feed_down to statuses and messages' do
        message = "The realtime feed is inaccessible via HTTP.\n"

        report_feed_down
        expect(@messages).to include message
        expect(@statuses.fetch(:feed_down)).to be true
      end
    end
  end
  describe 'report_missing_route' do
    context 'with parameters of route_number, headsign, gtfs_time' do
      it 'adds missing_route to statuses and messages' do
        route_and_headsign = "Route #{@route_number} with headsign #{@headsign} is missing:"
        expected_departure = 'Expected to be departing from Studio Arts Building'
        expected_time = "Expected scheduled departure time #{email_format @gtfs_time}"

        report_missing_route @route_number, @headsign, @gtfs_time
        expect(@messages.last).to include route_and_headsign
        expect(@messages.last).to include expected_departure
        expect(@messages.last).to include expected_time
        expect(@statuses.fetch(:missing_routes)).to include @route_number
      end
    end
  end
  describe 'report_incorrect_departure' do
    context 'with parameters of route_number, headsign, gtfs_time, avail_time, type' do
      it 'adds incorrect_departure to statuses and messages' do
        route_and_headsign = "Incorrect route #{@route_number} departure with headsign #{@headsign}:"
        type = "Saw #{@type} departure time,"
        expected_time = "expected to be #{email_format @gtfs_time};"
        avail_time = "Received #{email_format @avail_time}"

        report_incorrect_departure @route_number, @headsign, @gtfs_time, @avail_time, @type
        expect(@messages.last).to include route_and_headsign
        expect(@messages.last).to include type
        expect(@messages.last).to include expected_time
        expect(@messages.last).to include avail_time
        expect(@statuses.fetch(:incorrect_times)).to include @route_number
      end
    end
  end
  describe 'compare' do
    context 'with scheduled routes' do
      it 'checks if every route is present and next departure has correct scheduled time' do
        Bojangles.stub(:get_avail_departure_times!) do
          { ['30', '0', 'North Amherst'] =>
            ['07:28:08',
             '07:35:03',
             '08:01:40',
             '08:20:00',
             '08:31:38',
             '08:46:50',
             '09:03:19',
             '09:20:20',
             '09:35:40',
             '09:45:25',
             '10:00:22',
             '10:15:10'] }
        end
        departures = find_departures
        File.open 'cached_departures.json', 'w' do |file|
          file.puts departures.to_json
        end
        result = compare

        expect(result.first).to be @messages
        expect(result.last).to be @statuses
      end
    end
  end
end
