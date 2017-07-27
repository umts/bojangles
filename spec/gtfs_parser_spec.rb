# frozen_string_literal: true

require 'spec_helper'

describe GtfsParser do
  describe 'find_departures' do
    context 'with a trip ending at a stop and another beginning at the stop' do
      let(:result) { find_departures(%w[stop_id]) }
      it 'does not throw out the departure at the start of the trip' do
        expect_any_instance_of(GtfsParser)
          .to receive(:find_trips_operating_today)
          .and_return('trip_id1' => [:route_data1],
                      'trip_id2' => [:route_data2])
        row0 = { 'trip_id' => 'trip_id1', 'stop_id' => 'something else',
                 'departure_time' => '07:40:00' }
        # row1 marks the end of a trip. Since the trip ends at the stop, it is
        # not a departure and should not be included.
        row1 = { 'trip_id' => 'trip_id1', 'stop_id' => 'stop_id',
                 'departure_time' => '07:41:00' }
        # row2 is the beginning of a trip, so a perfectly legitimate departure,
        # and just happens to come after a trip end. It should be included.
        row2 = { 'trip_id' => 'trip_id2', 'stop_id' => 'stop_id',
                 'departure_time' => '08:21:00' }
        row3 = { 'trip_id' => 'trip_id2', 'stop_id' => 'something else',
                 'departure_time' => '08:22:00' }
        expect(CSV).to receive(:foreach).with(anything, headers: true)
          .and_yield(row0).and_yield(row1).and_yield(row2).and_yield(row3)
        expect(result).not_to be_empty
        expect(result).to eql ['stop_id', :route_data2] => ['08:21:00']
      end
    end
  end
end
