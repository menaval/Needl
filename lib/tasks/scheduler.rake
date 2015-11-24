# "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
  puts "Updating mailchimp infos ..."

  puts "done."
end
