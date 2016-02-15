require 'spec_helper'
include Bojangles

describe Bojangles do
  describe 'message_html' do
    let(:call) { message_html passes, failures, error_messages }
    let(:error_messages) { 'error messages' }
    let(:result) { call.split '<br>' }
    context 'with passes and no failures' do
      let(:passes) { 'passes' }
      let(:failures) { [] }
      before do
        allow_any_instance_of(Bojangles)
          .to receive(:message_list)
          .with 'passes', :passes, 'error messages'
      end
      it 'calls #message_list in passes mode' do
        call
      end
    end
    context 'with failures and no passes' do
      let(:passes) { [] }
      let(:failures) { 'failures' }
      before do
        allow_any_instance_of(Bojangles)
          .to receive(:message_list)
          .with 'failures', :failures, 'error messages'
      end
      it 'calls #message_list in failures mode' do
        call
      end
    end
    context 'with both failures and passes' do
      let(:passes) { 'passes' }
      let(:failures) { 'failures' }
      before do
        allow_any_instance_of(Bojangles)
          .to receive(:message_list)
          .with 'passes', :passes, 'error messages'
        allow_any_instance_of(Bojangles)
          .to receive(:message_list)
          .with 'failures', :failures, 'error messages'
      end
      it 'calls #message list in both passes and failures mode' do
        call
      end
      it 'has an introduction' do
        expect(result.first).to include 'brought to you by Bojangles'
      end
      it 'has a closing' do
        expect(result.last).to include 'You can trust Bojangles.'
      end
    end
  end

  describe 'message_list' do
    let(:errors) { [:error_name] }
    let(:error_messages){ { error_name: 'error message' } }
    let(:call) { message_list errors, mode, error_messages } 
    context 'dealing with failures' do
      let(:mode) { :failures }
      it 'has a sad-sounding first element' do
        expect(call.first).to include 'has noticed the following new errors'
      end
    end
    context 'dealing with passes' do
      let(:mode) { :passes } 
      it 'has a happy-sounding first element' do
        expect(call.first).to include 'pleased to report'
      end
    end
    let(:mode) { :failures }
    it 'has the error messages in a list as the second element' do
      expect(call.last).to start_with '<ul>'
      expect(call.last).to include '<li>error message'
      expect(call.last).to end_with '</ul>'
    end
  end
end
