require "slack-ruby-client"
require_relative "config"
require 'eventmachine'
require "pry"
require 'timeout'

module Wudu
  class SlackNotifier
    include Config
    attr_reader :users_with_positive_answer, :users_with_negative_answer
    def initialize(channel)
      @channel = channel
      @users_with_positive_answer = []
      @users_with_negative_answer = []
    end

    def post_message(message, user = channel)
      user == channel ? message(message, user) : ping(message, user) 
    end

    def ping(message, user)
      client = Slack::RealTime::Client.new
      client.on :hello do
        puts "Successfully connected, welcome '#{users[user]}' to the '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com."
      end
      message(message, user)
      begin
        Timeout::timeout(60) {
          client_asnwer(client)
        }
      rescue Timeout::Error
        EM.stop
      end
    end
    
    def client_asnwer(client)
      client.on :message do |data|
       unless include? users[data["user"]]
        case data['text'].downcase
        when /^yes/ 
          @users_with_positive_answer << users[data["user"]]
        when /^no/ 
          @users_with_negative_answer << users[data["user"]] 
        end
       end
      end
      client.start!
    end

    def users
      users ||= {}
      users_list.each do |member|
        user = user_info(member)
        if !user.is_bot
          users[member] = user.name
        end
      end
     users
    end

    def user_info(user)
      OpenStruct.new(
        slack.users_info(user: user).dig("user")
      )
    end

    def users_list
      channels_list.dig("members")
    end

    def channels_list
      slack.channels_info(channel: channel).dig("channel")
    end

    private

    attr_reader :channel
    
    def message(message, user)
      slack.chat_postMessage(
        channel: user,
        text: message,
        as_user: true
      )
    end
    
    def include?(user)
       users_with_positive_answer.include?(user) || users_with_negative_answer.include?(user)
    end
    
    def slack
      @slack ||= Slack::Web::Client.new
    end
  end
end