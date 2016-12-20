require 'spec_helper'
include DepartureComparator

describe DepartureComparator do
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
        @messages = ['error']
        @statuses = {feed_down: false, missing_routes: [39], incorrect_times: [39]}
        all_messages = Array.new
        all_messages += @messages + ["The realtime feed is inaccessible via HTTP.\n"]
        report_feed_down

        expect(all_messages).to eql @messages
        expect(@statuses.fetch :feed_down).to be true
      end
    end
  end
end