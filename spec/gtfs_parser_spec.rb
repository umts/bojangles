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
    context 'with a trip ending at a stop and another beginning at the stop' do
      it 'does not throw out the departure at the start of the trip' do
        expect_any_instance_of(GtfsParser)
          .to receive(:find_trips_operating_today).with('stop_id')
          .and_return('trip_id1' => :route_data1, 'trip_id2' => :route_data2)
        row0 = { 'trip_id' => 'trip_id1', 'stop_id' => 'something else' }
        # row1 marks the end of a trip. Since the trip ends at the stop, it is
        # not a departure and should not be counted.
        row1 = { 'trip_id' => 'trip_id1', 'stop_id' => 'stop_id',
                 'departure_time' => '07:41:00'}
        # row2 is the beginning of a trip, so a perfectly legitimate departure,
        # and just happens to come after a trip end. It should be included.
        row2 = { 'trip_id' => 'trip_id2', 'stop_id' => 'stop_id',
                 'departure_time' => '08:21:00'}
        row3 = { 'trip_id' => 'trip_id2', 'stop_id' => 'something else' }
        iterator = double
        expect(CSV).to receive(:foreach).with(anything, headers: true)
          .and_return iterator
        expect(iterator).to receive(:with_index)
          .and_yield(row0, 0).and_yield(row1, 1)
          .and_yield(row2, 2).and_yield(row3, 3)
        result = find_departures(%w[stop_id])
        expect(result).not_to be_empty
        expect(result).to eql route_data2: ['08:21:00']
      end
    end
  end
end
