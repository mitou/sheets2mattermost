#!/usr/bin/env ruby

GOOGLE_SHEETS_ID    = ENV.fetch('GOOGLE_SHEETS_ID')
GOOGLE_SECRETS      = ENV.fetch("GOOGLE_SECRETS")
GOOGLE_TOKENS       = ENV.fetch("GOOGLE_TOKENS")
MATTERMOST_ENDPOINT = ENV.fetch('MATTERMOST_ENDPOINT')

require 'net/http'
require 'json'
require 'yaml'
require "fileutils"

require "google/apis/sheets_v4"
require "googleauth"
require "googleauth/stores/file_token_store"

APPLICATION_NAME = "未踏ジュニア速報スクリプト"
SCOPE      = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY
TOKEN_PATH = File.join("./", 'tmp', "token.yaml")
def authorize
  #client_id = Google::Auth::ClientId.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'])
  #client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  client_id = Google::Auth::ClientId.from_hash(MultiJson.load(GOOGLE_SECRETS))

  FileUtils.mkdir_p(File.dirname TOKEN_PATH)
  File.open(TOKEN_PATH, "w") { |f| f.write GOOGLE_TOKENS.gsub("%", "\'") }
  token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
  authorizer  = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id     = 'default'
  credentials = authorizer.get_credentials(user_id)

  # NOTE: This doesn't work anymore due to OOB Authorization is outdated.
  #       Run `node .` that runs `index.js` script to refresh your token. ;)
  #       (Use Google Chrome Incognito Window if not authorzed by errors.)
  #if credentials.nil?
  #  oob = "urn:ietf:wg:oauth:2.0:oob"
  #  url = authorizer.get_authorization_url base_url: oob
  #  puts "Open the following URL in the browser and enter the resulting code after authorization:\n" + url
  #  code = gets
  #  credentials = authorizer.get_and_store_credentials_from_code(
  #          user_id: user_id, code: code, base_url: oob
  #      )
  #end

  credentials
end

# Initialize the API
service = Google::Apis::SheetsV4::SheetsService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# Fetch entries
IS_REPOST    = 23
FILE,TITLE   = 25,26
ABSTRACT     = 27
HAS_PROTO    = 28
entries      = []
range        = "A1:ZZ" # This covers almost all values in the sheet.
response     = service.get_spreadsheet_values(GOOGLE_SHEETS_ID, range)
list_of_rows = response.values.inject(&:zip).map(&:flatten)
list_of_rows.each.with_index do |row, index|
  next if index == 0 # The first row is label.

  #puts text = "#{index.to_s.rjust(3, '0')}: [#{row[TITLE]}](#{row[FILE]})"
  entries.push({
    id:        index,
    title:     row[TITLE],
    file:      row[FILE],
    abstract:  row[ABSTRACT],
    is_repost: row[IS_REPOST] == 'はい' ? true : false,
    has_proto: row[HAS_PROTO] == 'はい' ? true : false,
  })
end
#puts entries

def send_to_mattermost(text)
  uri     = URI.parse(MATTERMOST_ENDPOINT)
  request = Net::HTTP::Post.new(uri)
  request.content_type = 'application/json'
  request.body = JSON.dump({text: text})

  response = Net::HTTP.start(uri.hostname, uri.port, { use_ssl: uri.scheme == "https" }) do |http|
    http.request(request)
  end
end

ENTRY_ID_FILE = 'entry_id_list.yaml'.freeze
FileUtils.touch ENTRY_ID_FILE
entry_id_list = YAML.load(IO.read ENTRY_ID_FILE) || []

entries.each do |entry|
  # Skip already-notified entry
  next if entry_id_list.include? entry[:id]

  # Record new entry and notify it to Mattermost
  entry_id_list << entry[:id]
  id             = entry[:id].to_s.rjust(3, '0')
  title          = entry[:title]
  file           = entry[:file]
  abstract       = entry[:abstract]
  is_repost      = entry[:is_repost] ? '🆙' : '🆕'
  has_prototype  = entry[:has_proto] ? '(プロトタイプ有)' : ''
  text  = "#{is_repost} `#{id}` **#{title}** \[[提案書を見る](#{file})\] #{has_prototype}"
  text += "\n\n"
  text += "> #{abstract.lines.map(&:chomp).join("\n> ")}"

  # NOTE: GitHub Actions always set 'CI' true
  # https://docs.github.com/en/actions/learn-github-actions/variables#default-environment-variables
  ENV['CI'].eql?('true') ? send_to_mattermost(text) : puts(text + "\n\n")
end

IO.write(ENTRY_ID_FILE, entry_id_list.sort.reverse.to_yaml)
puts "✅ Successfully check entries."
