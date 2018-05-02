require 'rufus-scheduler'

# Let the bot remind you of something.
module Reminders
  extend Discordrb::Commands::CommandContainer

  @scheduler = Rufus::Scheduler.new

  attrs = {
    usage: '.remind <time> <message>',
    description: "You will be reminded of <message> after <time>. Argument order doesn't matter."
  }
  command :remind, attrs do |event, *args|
    time = args.select { |a| a =~ /^((\d+)[smhdwMy]{1})+$/ }.join
    msg  = args.reject { |a| a =~ /^((\d+)[smhdwMy]{1})+$/ || a.casecmp?('--pm') }.join(' ')
    pm = args.include?('--pm')
    time = '1d' if time.empty?

    event.respond "I will remind you about `#{msg}` in #{time}."
    @scheduler.in time do
      if pm
        event.user.pm "#{time} ago you wanted to be reminded about `#{msg}`."
      else
        event.respond "#{event.user.mention}, #{time} ago you wanted to be reminded about `#{msg}`."
      end
    end
    nil
  end
end
