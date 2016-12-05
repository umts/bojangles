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
    context 'with parameters' do
      it 'updates the log file' do
        filename = [LOG, "#{todays_date}.txt"].join '/'
        Bojangles.update_log_file!(to: "abc")
        expect(File.file? filename).to be true
        expect(File.read filename).to include "abc"
      end
    end
  end
end