module Comparator
  def self.compare(avail_departures, gtfs_departures)
    issues = []
    gtfs_departures.each_pair do |stop, route_directions|
      route_directions.each_pair do |route_direction, gtfs_time|
        route, headsign = route_direction
        avail_time = avail_departures[stop][route_direction]
        if avail_time.present?
          if avail_time != gtfs_time
            issues << { route: route, stop: stop, headsign: headsign,
                        issue_type: 'incorrect', sdt: gtfs_time,
                        alternatives: [avail_time] }
          end
        else
          binding.pry
          other_signs = alternative_headsigns(avail_departures, stop, route)
          issues << { route: route, stop: stop, headsign: headsign,
                      issue_type: 'missing', sdt: gtfs_time,
                      alternatives: other_signs }
        end
      end
    end
    issues
    []
  end

  private

  def self.alternative_headsigns(avail_departures, stop, desired_route)
    avail_departures[stop].values.map do |(route, headsign)|
      headsign if route == desired_route
    end.compact.sort
  end
end
