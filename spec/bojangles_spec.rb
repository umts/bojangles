require 'spec_helper'
include Bojangles
require 'json'
describe Bojangles do
  describe 'go!' do
    before :each do
      stub_request(:get, "http://bustracker.pvta.com/InfoPoint/rest/stopdepartures/get/72").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'bustracker.pvta.com', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})
      Pony.stub(:deliver) 
    end
    context 'with new error messages' do
      it 'sends an email, updates the log, and caches error messages' do
        DepartureComparator.stub(:compare) {
          [['error'], 
          {feed_down: false, missing_routes: [39], incorrect_times: [39]}]
        }
        expect_any_instance_of(Bojangles)
          .to receive :update_log_file!
        expect_any_instance_of(Bojangles)
          .to receive :cache_error_messages!
        Bojangles.go!
      end
    end
    context 'with old error messages' do
      it 'does nothing' do
        DepartureComparator.stub(:compare) {
          [['error'], 
          {feed_down: false, missing_routes: [39], incorrect_times: [39]}]
        }
        Bojangles.stub(:cached_error_messages) {
          ['error']
        }
        expect_any_instance_of(Bojangles)
          .not_to receive :anything
        Bojangles.go!
      end
    end
    context 'without error messages' do
      it 'does nothing' do
        DepartureComparator.stub(:compare) {
          [[], 
          {feed_down: false, missing_routes: [], incorrect_times: []}]
        }
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
        Bojangles.update_log_file!(to: { new_error: ['error_message'], current_time: Time.now })
        expect(File.file? filename).to be true
        expect(File.read filename).to include "New error: \"error_message\""
      end
    end
    context 'with one error_resolved' do
      it 'updates log file with one error' do
        filename = [LOG, "#{todays_date}.txt"].join '/'
        Bojangles.update_log_file!(to: { error_resolved: ['error_message'], current_time: Time.now + 1.hour })
        expect(File.file? filename).to be true
        expect(File.read filename).to include "New error: \"error_message\""
        expect(File.read filename).to include "Error resolved: \"error_message\""
      end
    end
    context 'with multiple errors' do
      it 'updates log file with errors' do
        filename = [LOG, "#{todays_date}.txt"].join '/'
        Bojangles.update_log_file!(to: { new_error: ['error1', 'error2'], current_time: Time.now })
        Bojangles.update_log_file!(to: { error_resolved: ['error3', 'error4'], current_time: Time.now + 1.hour })
        expect(File.file? filename).to be true
        expect(File.read filename).to include "New error: \"error1\""
        expect(File.read filename).to include "New error: \"error2\""
        expect(File.read filename).to include "Error resolved: \"error3\""
        expect(File.read filename).to include "Error resolved: \"error3\""
      end
    end
  end
  describe 'cache_error_messages!' do
    context 'with one error message' do
      it 'adds error in json to error messages file' do
        Bojangles.cache_error_messages!(['error_message'])
        expect(File.file? 'error_messages.json').to be true
        expect(File.read 'error_messages.json').to include "error_message".to_json
      end
    end
    context 'with multiple error messages' do
      it 'adds errors in json to error messages file' do
        Bojangles.cache_error_messages!(['error1', 'error2'])
        expect(File.file? 'error_messages.json').to be true
        expect(File.read 'error_messages.json').to include "error1".to_json
        expect(File.read 'error_messages.json').to include "error2".to_json
      end
    end
  end
end