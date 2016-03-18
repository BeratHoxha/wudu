module Config 
  # SLACK_API_TOKEN=xoxb-19469350855-pw8QfyEkHcPJAvgaasCcLqW5
  # run with SLACK_API_TOKEN=... bundle exec ruby wudu.rb

  Slack.configure do |config|
    config.token = ENV["SLACK_API_TOKEN"]
    fail 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
  end
  
  Slack::RealTime.configure do |config|
    config.concurrency = Slack::RealTime::Concurrency::Eventmachine
  end
end

