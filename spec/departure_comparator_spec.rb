# frozen_string_literal: true

require 'spec_helper'
require 'timecop'
include DepartureComparator
include GtfsParser

describe DepartureComparator do
  before :each do
    @issues = ['error']
    @all_messages = []
    @route_number = '45'
    @headsign = 'UMass'
    @gtfs_time = Time.now
    @type = 'EVE'
    @avail_time = Time.now + 2.minutes
    @stop_name = 'Fine Arts Center'
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
      it 'adds feed_down to messages' do
        message = "The realtime feed is inaccessible via HTTP.\n"

        report_feed_down
        expect(@issues).to include hash_including(message: message)
      end
    end
  end
  describe 'report_missing_route' do
    context 'with parameters of route_number, headsign, gtfs_time' do
      it 'adds missing_route to messages' do
        route_and_headsign =
          "Route #{@route_number} with headsign #{@headsign} is missing:"
        expected_departure =
          "Expected to be departing from #{@stop_name}"
        expected_time =
          "Expected SDT: #{email_format @gtfs_time}"

        report_missing_route @route_number, @headsign, @stop_name, @gtfs_time,
                             []
        message = @issues.last.fetch :message
        expect(message).to include route_and_headsign
        expect(message).to include expected_departure
        expect(message).to include expected_time
      end
    end
    context 'with an alternative headsign' do
      it 'suggests the alternative' do
        alternative = 'Found alternative: Another Destination'
        report_missing_route @route_number, @headsign, @stop_name, @gtfs_time,
                             ['Another Destination']
        expect(@issues.last.fetch(:message)).to include alternative
      end
    end
    context 'with alternative headsigns' do
      it 'suggests alternatives' do
        alternative = 'Found alternatives: Another Destination, And Another'
        report_missing_route @route_number, @headsign, @stop_name, @gtfs_time,
                             ['Another Destination', 'And Another']
        expect(@issues.last.fetch(:message)).to include alternative
      end
    end
  end
  describe 'report_incorrect_departure' do
    it 'adds incorrect_departure to messages' do
      route_and_headsign = "Incorrect route #{@route_number}"
      route_and_headsign += " SDT at #{@stop_name}"
      route_and_headsign += " with headsign #{@headsign}:"
      type = "Saw #{@type} departure time,"
      expected_time = "expected to be #{email_format @gtfs_time};"
      avail_time = "Received SDT #{email_format @avail_time}"

      report_incorrect_departure @route_number, @headsign, @stop_name,
                                 @gtfs_time, @avail_time, @type
      message = @issues.last.fetch :message
      expect(message).to include route_and_headsign
      expect(message).to include type
      expect(message).to include expected_time
      expect(message).to include avail_time
    end
  end

  describe 'compare' do
    context 'with a bus running late' do
      it 'reports incorrect departure' do
        Timecop.freeze(2016, 12, 12, 14, 0)
        early_sdt_time = Time.new(2016, 12, 12, 13, 58)
        @issues = ['error']
        expect(Bojangles)
          .to receive(:get_avail_departure_times!)
          .and_return(['31', 'North Amherst', 79] => early_sdt_time)
        expect_any_instance_of(GtfsParser)
          .to receive(:cached_stop_ids)
          .and_return(79 => 'My Awesome Stop')
        last_time = Time.new(2016, 12, 12, 13, 53)
        next_time = Time.new(2016, 12, 12, 14, 8)
        expect_any_instance_of(GtfsParser)
          .to receive(:soonest_departures_within)
          .and_return(79 => { %w[31 0] => ['North Amherst',
                                           last_time,
                                           next_time] })
        expect_any_instance_of(DepartureComparator)
          .to receive(:report_incorrect_departure)
          .with('31', 'North Amherst', 'My Awesome Stop',
                last_time, early_sdt_time, 'past')
          .and_return(@issues)

        expect(compare).to match_array(@issues)
        Timecop.return
      end
    end
    context 'with an early bus' do
      it 'reports incorrect departure' do
        Timecop.freeze(2016, 12, 12, 14, 0)
        late_sdt_time = Time.new(2016, 12, 12, 14, 5)
        @issues = ['error']
        expect(Bojangles)
          .to receive(:get_avail_departure_times!)
          .and_return(['31', 'North Amherst', 79] => late_sdt_time)
        expect_any_instance_of(GtfsParser)
          .to receive(:cached_stop_ids)
          .and_return(79 => 'My Awesome Stop')
        last_time2 = Time.new(2016, 12, 12, 13, 53)
        next_time2 = Time.new(2016, 12, 12, 14, 8)
        expect_any_instance_of(GtfsParser)
          .to receive(:soonest_departures_within)
          .and_return(79 => { %w[31 0] => ['North Amherst',
                                           last_time2,
                                           next_time2] })
        expect_any_instance_of(DepartureComparator)
          .to receive(:report_incorrect_departure)
          .with('31', 'North Amherst', 'My Awesome Stop',
                next_time2, late_sdt_time, 'future')
          .and_return(@issues)

        expect(compare).to match_array(@issues)
        Timecop.return
      end
    end
  end
end
