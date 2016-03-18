require "slack-ruby-client"
require_relative "config"
require "pry"
require 'timeout'
require_relative 'wudu'

module Wudu
 class Notifier
   attr_reader :wudu, :threads
   def initialize(channel)
     @wudu = Wudu::SlackNotifier.new(channel)
     ask_and_notify_members
   end
    
   def ask_and_notify_members
     @count = 0
     prepare_ask_for_members
     notify_members
   end
  
   def prepare_ask_for_members(users = wudu.users)
     @threads = []
     users.each_key do |k| 
       @threads << Thread.new do
         wudu.ping("Do you have wudu ( yes or no ) ?", k)
       end
     end
     ask_members
     repeat_ask_for_some_users
   end
   
   def ask_members
     threads.each do |thread|
       thread.join
     end
   end

   def repeat_ask_for_some_users 
     @count += 1 
     users_with_no_answer = {}
     wudu.users.each do |k, v| 
      if !wudu.users_with_negative_answer.include?(v) && !wudu.users_with_positive_answer.include?(v)
         users_with_no_answer.merge!({k => v}) 
      end
     end
     prepare_ask_for_members(users_with_no_answer) if @count < 4
   end
   
   def notify_members
     if wudu.users_with_negative_answer == []
       wudu.post_message("All members have wudu.")
     else
       wudu.post_message( "Time to take wudu: " )
       @time = Time.now
   	   post_notify
   	   positive_answer
     end
   end
   
   def post_notify
   	 wudu.users_with_negative_answer.each do |member|
       p member
       @time += 4*60 
       t1 = @time + 3*60
       wudu.post_message( "- " + member.capitalize + ' : ' +  @time.strftime("%I:%M") + ' - ' +  t1.strftime("%I:%M") )
     end
   end

   def positive_answer
   	   wudu.post_message( "People who have wudu: " )
	   @time = Time.now
	   wudu.users_with_positive_answer.each do |member|
      	 wudu.post_message( "- " + member.capitalize )
       end
   end
 end
end

wudu = Wudu::Notifier.new("#test_wudu")