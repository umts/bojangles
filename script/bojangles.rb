require 'json'
require 'net/http'
require 'pony'
require 'redcarpet'

PVTA_API_URL = 'http://bustracker.pvta.com/InfoPoint/rest'
ROUTES_URI = URI([PVTA_API_URL, 'routes', 'getvisibleroutes'].join '/')
STUDIO_ARTS_BUILDING_ID = 58
DEPARTURES_URI = URI([PVTA_API_URL, 'stopdepartures', 'get', STUDIO_ARTS_BUILDING_ID].join '/')

def get_nabr_id!
  response = JSON.parse(Net::HTTP.get ROUTES_URI)
  nabr = response.find{|route| route['LongName'] == 'North Amherst / Old Belchertown Rd'}
  nabr.fetch 'RouteId'
end

def is_nabr_done?
  response = JSON.parse(Net::HTTP.get DEPARTURES_URI)
  route_directions = response.first.fetch 'RouteDirections'
  route_id = get_nabr_id!
  @problem_json = route_directions.find{|data| data['RouteId'] == route_id}
  @problem_json.fetch 'IsDone'
end

def markdown_pretty_json
  renderer = Redcarpet::Render::HTML.new
  markdown = Redcarpet::Markdown.new renderer 
  markdown.render <<-CODE
    ```json
      #{JSON.pretty_generate @problem_json}
    ```
  CODE
end

is_nabr_done?

mail_settings = {
  to: 'transit-it@umass.edu',
  from: 'transit-it@admin.umass.edu',
  subject: 'PVTA realtime feed error',
  html_body: <<-BODY
    The 30 is shown as being done for the day.
    Details:
    #{markdown_pretty_json}
  BODY
}

if ENV['BOJANGLES_DEVELOPMENT']
  mail_settings.merge! via: :smtp, via_options: { address: 'localhost', port: 1025 }
end

Pony.mail mail_settings
