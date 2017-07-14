# frozen_string_literal: true

require 'spec_helper'
include Bojangles
require 'json'

describe Bojangles do
  describe 'go!' do
    before :each do
      stub_request(:get, 'http://bustracker.pvta.com/InfoPoint/rest/stopdepartures/get/72')
        .with(headers: {
                'Accept' => '*/*',
                'Host' => 'bustracker.pvta.com',
                'User-Agent' => 'Ruby'
              }).to_return(status: 200, body: '', headers: {})
      allow(Pony).to receive(:deliver)
    end
    context 'with new error messages' do
      it 'updates the log and caches error messages' do
        DepartureComparator.stub(:compare) do
          [['error'],
           { feed_down: false, missing_routes: [39], incorrect_times: [39] }]
        end
        expect_any_instance_of(Bojangles)
          .to receive :update_log_file!
        expect_any_instance_of(Bojangles)
          .to receive :cache_error_messages!
        Bojangles.go!
      end
    end
    context 'with old error messages' do
      it 'does nothing' do
        DepartureComparator.stub(:compare) do
          [['error'],
           { feed_down: false, missing_routes: [39], incorrect_times: [39] }]
        end
        Bojangles.stub(:cached_error_messages) do
          ['error']
        end
        expect_any_instance_of(Bojangles)
          .not_to receive :anything
        Bojangles.go!
      end
    end
    context 'without error messages' do
      it 'does nothing' do
        DepartureComparator.stub(:compare) do
          [[],
           { feed_down: false, missing_routes: [], incorrect_times: [] }]
        end
        expect_any_instance_of(Bojangles)
          .not_to receive :anything
        Bojangles.go!
      end
    end
  end
  describe 'update_log_file' do
    context 'with one new_error' do
      it 'updates log file with one error' do
        filename = [LOG, "#{todays_date}.txt"].join '/'
        Bojangles.update_log_file!(to: { new_error: ['error_message'],
                                         current_time: Time.now })
        expect(File.file?(filename)).to be true
        expect(File.read(filename)).to include 'New error: "error_message"'
      end
    end
    context 'with one error_resolved' do
      it 'updates log file with one error' do
        filename = [LOG, "#{todays_date}.txt"].join '/'
        Bojangles.update_log_file!(to: { error_resolved: ['error_message'],
                                         current_time: Time.now + 1.hour })
        expect(File.file?(filename)).to be true

        # File isn't overwritten with each update.
        # Previous entries are still there.
        result = File.read(filename)
        expect(result).to include 'New error: "error_message"'
        expect(result).to include 'Error resolved: "error_message"'
      end
    end
    context 'with multiple errors' do
      it 'updates log file with errors' do
        filename = [LOG, "#{todays_date}.txt"].join '/'
        Bojangles.update_log_file!(to: { new_error: %w[error1 error2],
                                         current_time: Time.now })
        Bojangles.update_log_file!(to: { error_resolved: %w[error3 error4],
                                         current_time: Time.now + 1.hour })
        expect(File.file?(filename)).to be true

        result = File.read(filename)
        expect(result).to include 'New error: "error1"'
        expect(result).to include 'New error: "error2"'
        expect(result).to include 'Error resolved: "error3"'
        expect(result).to include 'Error resolved: "error3"'
      end
    end
  end
  describe 'cached_route_mappings' do
    before :each do
      stub_request(:get, 'http://bustracker.pvta.com/InfoPoint/rest/routes/getvisibleroutes')
        .with(headers: {
                'Accept' => '*/*',
                'Host' => 'bustracker.pvta.com',
                'User-Agent' => 'Ruby'
              }).to_return(status: 200, body: '', headers: {})
    end
    context 'with bojangles daily task' do
      it 'returns the cached route mappings' do
        routes = { '30' => '20_030', '10' => '20_010' }
        File.open CACHED_ROUTES_FILE, 'w' do |file|
          file.puts routes.to_json
        end
        result = Bojangles.cached_route_mappings
        expect(result).to include routes
      end
    end
  end

  describe 'cache_route_mappings!' do
    before :each do
      routes = [{ ShortName: 30, RouteId: 20_030 },
                { ShortName: 10, RouteId: 20_010 }].to_json
      stub_request(:get, 'http://bustracker.pvta.com/InfoPoint/rest/routes/getvisibleroutes')
        .with(headers: {
                'Accept' => '*/*',
                'Host' => 'bustracker.pvta.com',
                'User-Agent' => 'Ruby'
              }).to_return(status: 200, body: routes, headers: {})
    end
    context 'with routes' do
      it 'creates a file of json routes' do
        Bojangles.cache_route_mappings!
        expect(File.file?('route_mappings.json')).to be true
        expect(File.read('route_mappings.json')).to include '"20030":30'
      end
    end
  end
  describe 'cached_error_messages' do
    context 'without an error messages file' do
      it 'returns an empty array' do
        expect(File.file?('error_messages.json')).to be false
        expect(Bojangles.cached_error_messages).to eql []
      end
    end
    context 'with an error messages file' do
      it 'returns the error messages in the file' do
        Bojangles.stub(:cache_error_messages!) do
          File.open 'error_messages.json', 'w' do |file|
            file.puts ['error_message'].to_json
          end
        end
        Bojangles.cache_error_messages!
        expect(File.file?('error_messages.json')).to be true
        expect(Bojangles.cached_error_messages).to include 'error_message'
        FileUtils.rm 'error_messages.json'
      end
    end
  end
  describe 'get_avail_departure_times' do
    context 'with departures and multiple stop_ids' do
      it 'maps route number and headsign to the provided time' do
        Bojangles.stub(:cache_route_mappings!) do
          routes = [{ ShortName: 30, RouteId: 20_030 },
                    { ShortName: 10, RouteId: 20_010 },
                    { ShortName: 45, RouteId: 20_045 }]
          File.open CACHED_ROUTES_FILE, 'w' do |file|
            file.puts routes.to_json
          end
        end
        Bojangles.stub(:cached_route_mappings) do
          { '20030' => '30', '20010' => '10', '20045' => '45' }
        end
        Bojangles.stub(:parse_json_unix_timestamp) do
          '2016-12-12 14:00:00 -0500'
        end

        dept1 = { SDT: '13:00', Trip: { InternetServiceDesc: 'Garage' } }
        dept2 = { SDT: '12:00', Trip: { InternetServiceDesc: 'CompSci' } }
        route_directions = [
          { ShortName: 30, RouteId: 20_030, Departures: [dept1] },
          { ShortName: 10, RouteId: 20_010, Departures: [dept2] }
        ]
        response_body = [{ RouteDirections: route_directions }].to_json
        stub_request(:get, 'http://bustracker.pvta.com/InfoPoint/rest/stopdepartures/get/72')
          .with(headers: {
                  'Accept' => '*/*',
                  'Host' => 'bustracker.pvta.com',
                  'User-Agent' => 'Ruby'
                }).to_return(status: 200, body: response_body, headers: {})

        dept3 = { SDT: '14:00', Trip: { InternetServiceDesc: 'LRC' } }
        route_directions2 = [
          { ShortName: 45, RouteId: 20_045, Departures: [dept3] }
        ]
        response_body2 = [{ RouteDirections: route_directions2 }].to_json
        stub_request(:get, 'http://bustracker.pvta.com/InfoPoint/rest/stopdepartures/get/79')
          .with(headers: {
                  'Accept' => '*/*',
                  'Host' => 'bustracker.pvta.com',
                  'User-Agent' => 'Ruby'
                })
          .to_return(status: 200, body: response_body2, headers: {})
        Bojangles.cache_route_mappings!
        result = Bojangles.get_avail_departure_times!([72, 79])

        expect(result).is_a? Hash
        expect(result).to include ['10', 'CompSci', 72] =>
                                  '2016-12-12 14:00:00 -0500'
        expect(result).to include ['30', 'Garage', 72] =>
                                  '2016-12-12 14:00:00 -0500'
        expect(result).to include ['45', 'LRC', 79] =>
                                  '2016-12-12 14:00:00 -0500'
      end
    end
    context 'without departures' do
      it 'returns an empty hash' do
        Bojangles.stub(:cache_route_mappings!) do
          routes = { '30' => '20_030', '10' => '20_010' }
          File.open CACHED_ROUTES_FILE, 'w' do |file|
            file.puts routes.to_json
          end
        end
        Bojangles.cache_route_mappings!
        route_directions = [
          { ShortName: 30, RouteId: 20_030, Departures: [] },
          { ShortName: 10, RouteId: 20_010, Departures: [] }
        ]
        response_body = [{ RouteDirections: route_directions }].to_json
        stub_request(:get, 'http://bustracker.pvta.com/InfoPoint/rest/stopdepartures/get/72')
          .with(headers: {
                  'Accept' => '*/*',
                  'Host' => 'bustracker.pvta.com',
                  'User-Agent' => 'Ruby'
                }).to_return(status: 200, body: response_body, headers: {})

        # Get the avail departure times for SAB ID = 72
        result = Bojangles.get_avail_departure_times!([72])
        expect(result).is_a? Hash
        expect(result).to be_empty
      end
    end
  end
  describe 'cache_error_messages!' do
    after(:each) { FileUtils.rm 'error_messages.json' }
    context 'with one error message' do
      it 'adds error in json to error messages file' do
        Bojangles.cache_error_messages!(['error_message'])
        expect(File.file?('error_messages.json')).to be true
        expect(File.read('error_messages.json')).to include 'error_message'
      end
    end
    context 'with multiple error messages' do
      it 'adds errors in json to error messages file' do
        Bojangles.cache_error_messages!(%w[error1 error2])
        expect(File.file?('error_messages.json')).to be true

        result = File.read('error_messages.json')
        expect(result).to include 'error1'
        expect(result).to include 'error2'
      end
    end
  end
  describe 'parse_json_unix_timestamp' do
    context 'correctly formatted timestamp' do
      it 'returns the time' do
        timestamp = '/Date(1481569200000-0500)/'
        expect(Bojangles.parse_json_unix_timestamp(timestamp).to_s)
          .to eql '2016-12-12 14:00:00 -0500'
      end
      it 'strips seconds' do
        timestamp = '/Date(1500061264000-0500)/'
        expect(Bojangles.parse_json_unix_timestamp(timestamp).to_s)
          .to eql '2017-07-14 15:41:00 -0500'
      end
    end
  end
  describe 'message_html' do
    context 'with error messages' do
      it 'creates a message' do
        Bojangles.stub(:message_list) do
          'error message list'
        end
        message = <<~message.tr("\n", ' ')
          This message brought to you by Bojangles, UMass Transit's
          monitoring service for the PVTA realtime bus departures feed.
        message
        expect(Bojangles.message_html(%w[error1 error2], current: true))
          .to include message + '<br>' + Bojangles.message_list
      end
    end
  end
  describe 'message_list' do
    context 'with new error messages' do
      it 'creates a message_list of given heading and error messages' do
        heading = 'Bojangles has noticed the following errors:'
        result = Bojangles.message_list(%w[error1 error2], current: true)
        expect(result.first).to include heading
        expect(result.last).to include 'error1'
        expect(result.last).to include 'error2'
      end
    end
    context 'with resolved error messages' do
      it 'creates a message_list of given heading and error messages' do
        heading = 'This error has been resolved:'
        result = Bojangles.message_list(%w[error1 error2], current: false)
        expect(result.first).to include heading
        expect(result.last).to include 'error1'
        expect(result.last).to include 'error2'
      end
    end
  end
end
