require "bundler/setup"

# Tasks triggered by GitHub Actions
desc "Notify new entry to Mattermost channel"
task :notify_new_entry_to_mattermost do |task, args|
  ruby "sheets2mattermost.rb"
end
