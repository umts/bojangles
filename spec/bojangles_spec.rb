require 'spec_helper'
include Bojangles

describe Bojangles do
  describe 'message_list' do
    let(:errors) { [:error_name] }
    let(:error_messages){ { error_name: 'error message' } }
    let(:call) { message_list errors, mode, error_messages } 
    context 'dealing with passes' do
      let(:mode) { :passes } 
      it 'has a happy-sounding first element' do
        expect(call.first).to include 'pleased to report'
      end
    end
  end
end
