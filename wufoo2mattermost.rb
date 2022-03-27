#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'time'
#require 'active_support'

WUFOO_API_USERNAME  = ENV['WUFOO_API_USERNAME']
WUFOO_API_PASSWORD  = ENV['WUFOO_API_PASSWORD']
WUFOO_API_SUBDOMAIN = ENV['WUFOO_API_SUBDOMAIN']
WUFOO_API_FORM_ID   = ENV['WUFOO_API_FORM_ID']
MATTERMOST_ENDPOINT = ENV['MATTERMOST_ENDPOINT']

base_domain = "https://#{WUFOO_API_SUBDOMAIN}.wufoo.com"

# Sample URI to get 'form' information.
# 'form' can be replaced  with '[fields|entries].json]
# https://wufoo.github.io/docs/?ruby#introduction
#
# Exec this to get Wufoo form IDs and set it to the env variable.
# uri = URI.parse(base_domain + '/api/v3/forms.json')

# Get given form entries via API
uri = URI.parse(base_domain + "/api/v3/forms/#{WUFOO_API_FORM_ID}/entries.json?sort=EntryId&sortDirection=DESC")

# Set up our request using the desired endpoint, and configure the basic auth
request = Net::HTTP::Get.new(uri.request_uri)
request.basic_auth(WUFOO_API_USERNAME, WUFOO_API_PASSWORD)

# Make our request using https
response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
  http.request(request)
end

# Print the output in a "pretty" json format
puts JSON.pretty_generate(JSON[response.body])

# The following code is optimezed for Mitou Junior entry, so
# this won't be worked. Please change each field on your own.

JSON.parse(response.body)['Entries'].each do |entry|
  pp Time.parse("#{entry['DateCreated']} +0900")
  #binding.irb
end
