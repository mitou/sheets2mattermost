require "bundler/setup"

# Tasks triggered by GitHub Actions
desc "Notify new Wufoo entry to Mattermost channel"
task :notify_wufoo_entry_to_mattermost do |task, args|
  ruby "wufoo2mattermost.rb"
end
