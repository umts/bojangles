require 'spec_helper'
include DepartureComparator

describe DepartureComparator do
  before :each do
    @messages = ['error']
    @statuses = {feed_down: false, missing_routes: [], incorrect_times: []}
    all_messages = Array.new
  end
  describe 'email_format' do
    context 'with time parameter' do
      it 'formats the time' do
        time = Time.now
        expect(email_format time).to eql time.strftime '%I:%M:%S %p'
      end
    end
  end
  describe 'report_feed_down' do
    context 'with previous messages' do
      it 'changes feed_down status and adds to messages' do
        all_messages = @messages << "The realtime feed is inaccessible via HTTP.\n"
        report_feed_down

        expect(all_messages).to eql @messages
        expect(@statuses.fetch :feed_down).to be true
      end
    end
  end
  describe 'report_missing_route' do
    context 'with parameters of route_number, headsign, gtfs_time' do
      it 'adds to missing_routes status and adds to messages' do
        route_number = '45'
        headsign = 'UMass'
        gtfs_time = Time.now
        all_messages = @messages << "Route #{route_number} with headsign #{headsign} is missing:
          Expected to be departing from Studio Arts Building
          Expected scheduled departure time #{email_format gtfs_time}"
        report_missing_route route_number, headsign, gtfs_time

        expect(all_messages).to eql @messages
        expect(@statuses.fetch :missing_routes).to include route_number
      end
    end
  end
  describe 'report_incorrect_departure' do
    context 'with parameters of route_number, headsign, gtfs_time, avail_time, type' do
      it 'adds to incorrect_times and adds to messages' do
        route_number = '45'
        headsign = 'UMass'
        gtfs_time = Time.now
        type = 'EVE'
        avail_time = Time.now + 2.minutes
        all_messages = @messages << "Incorrect route #{route_number} departure with headsign #{headsign}:
          Saw #{type} departure time, expected to be #{email_format gtfs_time};
          Received #{email_format avail_time}"
        report_incorrect_departure route_number, headsign, gtfs_time, avail_time, type
        
        expect(all_messages).to eql @messages
        expect(@statuses.fetch :incorrect_times).to include route_number
      end
    end
  end
end