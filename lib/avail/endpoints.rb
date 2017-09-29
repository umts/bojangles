require 'json'
require 'net/http'

module Avail
  module Endpoints
    PVTA_BASE_API_URL = 'https://bustracker.pvta.com/InfoPoint/rest'

    def self.route_mappings
      routes_uri = URI([PVTA_BASE_API_URL, 'routes', 'getvisibleroutes'].join '/')
      response = JSON.parse Net::HTTP.get(routes_uri)
      routes = {}
      response.each do |route|
        real_name = route.fetch 'ShortName'
        avail_id = route.fetch 'RouteId'
        routes[real_name] = avail_id
      end
      routes
    end
  end
end
