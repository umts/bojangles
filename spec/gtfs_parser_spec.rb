# frozen_string_literal: true
# frozen_string_literal: true

require 'spec_helper'

describe GtfsParser do
  describe 'find_departures' do
    context 'with multiple stops' do
      it 'finds departures at that route' do
        stops = ['North Amherst', 'Graduate Research Center']
        result = find_departures(stops)
        # hash keyed by route ID, direction, and headsign to an array of times
        expect(result.key?(%w[31 31 0 Sunderland]))
        expect(result[%w[31 31 0 Sunderland]]).is_a? Array
      end
    end
  end
end
