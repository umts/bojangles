require 'active_support/core_ext/object/blank'
require 'json'
require 'net/http'
require 'pony'

module Bojangles
  config_file = File.read 'config.json'
  CONFIG = JSON.parse config_file

  PVTA_API_URL = 'http://bustracker.pvta.com/InfoPoint/rest'
  ROUTES_URI = URI([PVTA_API_URL, 'routes', 'getvisibleroutes'].join '/')
  STUDIO_ARTS_BUILDING_ID = 72
  DEPARTURES_URI = URI([PVTA_API_URL, 'stopdepartures', 'get', STUDIO_ARTS_BUILDING_ID].join '/')

  MAIL_SETTINGS = CONFIG.fetch 'mail_settings'

  status_file = File.read 'emailed_status.json'
  EMAILED_STATUS = JSON.parse status_file

  # NO TESTS: we're gonna throw this out
  def get_nabr_id!
    response = JSON.parse(Net::HTTP.get ROUTES_URI)
    nabr = response.find { |route| route['LongName'] == 'North Amherst / Old Belchertown Rd' }
    nabr.fetch 'RouteId'
  end

  def go!
    error_messages = CONFIG.fetch('error_messages').symbolize_keys
    error_methods = error_messages.keys

    current_status = EMAILED_STATUS
    passes, failures = [], []

    error_methods.each do |error|
      status = send error
      emailed_status = EMAILED_STATUS.fetch error.to_s
      if status != emailed_status
        (status ? failures : passes).send :<<, error
        current_status.merge! error.to_s => status
      end
    end

    if passes.present? || failures.present?
      MAIL_SETTINGS.merge! html_body: message_html(passes, failures, error_messages)
      if CONFIG['environment'] == 'development'
        MAIL_SETTINGS.merge! via: :smtp, via_options: { address: 'localhost', port: 1025 }
      end
      Pony.mail MAIL_SETTINGS
      update_emailed_status! to: current_status
    end
  end

  # NO TESTS: we're gonna throw this out
  def is_nabr_done?
    response = JSON.parse(Net::HTTP.get DEPARTURES_URI)
    route_directions = response.first.fetch 'RouteDirections'
    route_id = get_nabr_id!
    departure = route_directions.find{ |data| data['RouteId'] == route_id }
    departure.fetch 'IsDone'
  end

  def message_html(passes, failures, error_messages)
    message = ["This message brought to you by Bojangles, UMass Transit's monitoring service for the PVTA realtime bus departures feed."]
    message << message_list(failures, :failures, error_messages) if failures.present?
    message << message_list(passes,   :passes,   error_messages) if passes.present?
    message << 'Bojangles will let you know if anything changes. You can trust Bojangles.'
    message.flatten.join '<br>'
  end

  def message_list(errors, mode, error_messages)
    heading = case mode
              when :passes then 'Bojangles is pleased to report that the following errors seem to have been resolved:'
              when :failures then 'Bojangles has noticed the following new errors:'
              end
    list = '<ul>'
    errors.each do |error|
      list << "<li>#{error_messages.fetch error}"
    end
    list << '</ul>'
    [heading, list]
  end

  def update_emailed_status!(to:)
    File.open 'emailed_status.json', 'w' do |file|
      file.puts to.to_json
    end
  end
end