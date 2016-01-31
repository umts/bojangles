require 'sinatra'
require 'haml'
require 'net/http'
require 'json'
require 'pry-byebug'

PVTA_API_URL = 'http://bustracker.pvta.com/InfoPoint/rest'
ROUTES_URI = URI([PVTA_API_URL, 'routes', 'getvisibleroutes'].join '/')
STUDIO_ARTS_BUILDING_ID = 58
DEPARTURES_URI = URI([PVTA_API_URL, 'stopdepartures', 'get', STUDIO_ARTS_BUILDING_ID].join '/')

helpers do
  def get_nabr_id!
    response = JSON.parse(Net::HTTP.get ROUTES_URI)
    nabr = response.find{|route| route['LongName'] == 'North Amherst / Old Belchertown Rd'}
    nabr.fetch 'RouteId'
  end

  def is_nabr_done?
    response = JSON.parse(Net::HTTP.get DEPARTURES_URI)
    route_directions = response.first.fetch 'RouteDirections'
    route_id = get_nabr_id!
    nabr_departures = route_directions.find{|data| data['RouteId'] == route_id}
    nabr_departures.fetch 'IsDone'
  end
end

get '/' do
  @done = is_nabr_done?
  haml :index
end

