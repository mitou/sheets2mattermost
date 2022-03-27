#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'time'

WUFOO_API_USERNAME  = ENV['WUFOO_API_USERNAME']
WUFOO_API_PASSWORD  = ENV['WUFOO_API_PASSWORD']
WUFOO_API_SUBDOMAIN = ENV['WUFOO_API_SUBDOMAIN']
WUFOO_API_FORM_ID   = ENV['WUFOO_API_FORM_ID']
MATTERMOST_ENDPOINT = ENV['MATTERMOST_ENDPOINT']

def send_to_mattermost(text)
  uri     = URI.parse(MATTERMOST_ENDPOINT)
  request = Net::HTTP::Post.new(uri)
  request.content_type = 'application/json'
  request.body = JSON.dump({text: text})

  response = Net::HTTP.start(uri.hostname, uri.port, { use_ssl: uri.scheme == "https" }) do |http|
    http.request(request)
  end
end

def fetch_wufoo_form_entries
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

  # The following code is optimezed for Mitou Junior entry, so
  # this won't be worked. Please change each field on your own.
  #
  # Entry Field Info:
  # - entry['Field206'] # Project Title
  # - entry['Field168'] # has_prototype? (はい/いいえ)
  # - entry['Field208'] # is_new_submit? (or update?)
  # - entry['Field1']   # Project Details (URL)
  # - entry['DateCreated'] # No timezone info

  response
end

#TIME_INTERVAL = 10 # minutes
TIME_INTERVAL = 60 * 24 * 7 # 7 days for debugging
JSON_RESPONSE = fetch_wufoo_form_entries
text_to_post  = ''
JSON.parse(JSON_RESPONSE.body)['Entries'].each do |entry|
  # Skip WIP or not-recent entries
  next if entry['Field1'].empty?
  next if (Time.now.round - Time.parse("#{entry['DateCreated']} +0900")).to_i > TIME_INTERVAL * 60 # seconds

  project_title = entry['Field206']
  has_prototype = entry['Field168'].include?('はい') ? '(プロトタイプ有)' : ''
  is_this_update  = entry['Field208'].include?('はい') ? '🔁' : '🆕'
  project_details = entry['Field1'].split.last.delete('()') # Project Details (URL)

  text_to_post += "- #{is_this_update} #{project_title} \[[Download](#{project_details})\] #{has_prototype}\n"
end

send_to_mattermost(text_to_post) unless text_to_post.empty?
puts "✅ Successfully check entries."
