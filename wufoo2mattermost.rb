#!/usr/bin/env ruby

require "net/http"
require "uri"
require "json"

WUFOO_API_USERNAME  = ENV['WUFOO_API_USERNAME']
WUFOO_API_PASSWORD  = ENV['WUFOO_API_PASSWORD']
WUFOO_API_SUBDOMAIN = ENV['WUFOO_API_SUBDOMAIN']
WUFOO_API_FORM_ID   = ENV['WUFOO_API_FORM_ID']
MATTERMOST_ENDPOINT = ENV['MATTERMOST_ENDPOINT']

base_url = "https://#{WUFOO_API_SUBDOMAIN}.wufoo.com/api/v3/"

# Sample URI to get 'form' information.
# 'form' can be replaced  with '[fields|entries].json]
# https://wufoo.github.io/docs/?ruby#introduction
#
# Exec this to get Wufoo form IDs and set it to the variable
# uri = URI.parse(base_url + 'forms.json')

# Get given entries via API
uri = URI.parse(base_url + 'entries.json')

# Set up our request using the desired endpoint, and configure the basic auth
request = Net::HTTP::Get.new(uri.request_uri)
request.basic_auth(WUFOO_API_USERNAME, WUFOO_API_PASSWORD)

# Make our request using https
response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
  http.request(request)
}

# Print the output in a "pretty" json format
puts JSON.pretty_generate(JSON[response.body])
