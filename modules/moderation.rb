require 'rufus-scheduler'

# Tools for moderating a server
module Moderation
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  @scheduler = Rufus::Scheduler.new
  # User => [Job, reason]
  @mutes = {}

  TIME_FORMAT = '%A, %d. %B, %Y at %-l:%M:%S%P %Z'.freeze

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'mute <userMentions> <duration> <reason>',
    description: 'Mutes all users mentioned in the command for the duration given. '\
                 'Order doesn\'t matter, duration and reason are optional',
    min_args: 1
  }
  command :mute, attrs do |event, *args|
    # Rejects the mentions and everything that doesn't fit the time format from the  list of args.
    time = args.reject { |x| x =~ /<@!?(\d+)>/ || x !~ /^((\d+)[smhdwMy]{1})+$/ }.join
    # Defaults to one day if it couldn't find a legit time.
    time = '1d' if time.empty?

    reason = args.reject { |x| x =~ /<@!?(\d+)>/ || x =~ /^((\d+)[smhdwMy]{1})+$/ }.join(' ')
    reason = '`No reason provided`' if reason.empty?

    users = event.message.mentions
    next 'Please mention at least one user to be muted.' if users.empty?
    mute(event, users, time, reason)
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'unmute <userMentions>',
    description: 'Unmutes all users mentioned in the command.'
  }
  command :unmute, attrs do |event|
    users = event.message.mentions
    unmuted = []
    users.each do |user|
      if @mutes[user]
        unmute(event, user)
        unmuted << user.distinct
      end
    end

    if users.size - unmuted.size == 1
      event.respond "User `#{(users.map!(&:distinct) - unmuted).join}` isn't muted."
    elsif unmuted.size != users.size
      event.respond "Users `#{(users.map!(&:distinct) - unmuted).join('`, `')}` aren't muted."
    end

    LOGGER.log(event.server, "Successfully unmuted `#{unmuted.join('`, `')}`.") unless unmuted.empty?
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'mutes',
    description: 'Lists all muted people, and the time their mute expires.'
  }
  command :mutes, attrs do |event|
    next 'No users are currently being muted.' if @mutes.empty?

    embed = Discordrb::Webhooks::Embed.new

    @mutes.each_pair do |user, info|
      embed.add_field(
        name: "**#{user.distinct}**",
        value: "#{info[0].next_time.strftime("Muted until #{TIME_FORMAT}")}\n**Reason:** #{info[1]}"
      )
    end

    embed.colour = 3715045
    embed.footer = {
      text: 'All muted users.',
      icon_url: SHRK.profile.avatar_url
    }
    embed.timestamp = Time.now

    event.channel.send_embed('', embed)
  end

  command :pruneMutes do |event|
    next unless event.user.id == 94558130305765376
    f = File.open('mute_dump.txt', 'w+')
    f.write(@mutes)
    f.close
    SHRK.user(94558130305765376).pm.send_file(File.open('mute_dump.txt'))
    @mutes.each_pair do |user, info|
      @mutes.delete(user) if info[0].next_time.nil?
    end
    'Done.'
  end

  def self.mute(event, users, time, reason, logging: true)
    deny = Discordrb::Permissions.new
    deny.can_send_messages = true
    deny.can_speak = true

    users.each do |user|
      event.server.channels.each do |channel|
        channel.define_overwrite(user, 0, deny)
      end
      schedule_unmute(event, user, time)
      @mutes[user][1] = reason
    end

    if logging
      LOGGER.log(event.server, "Successfully muted `#{users.map(&:distinct).join('`, `')}` until "\
                "#{@mutes[users.first][0].next_time.strftime(TIME_FORMAT)}. Reason: **#{reason}**.")
    end
  end

  # Schedules the unmute for a user
  private_class_method def self.schedule_unmute(event, user, time)
    @mutes[user]&.at(0)&.unschedule

    @mutes[user] = []
    @mutes[user][0] = @scheduler.in(time, job: true) do
      user.pm("You're no longer muted for **#{@mutes[user][1]}** in `#{event.server.name}`.")
      unmute(event, user)
    end
  end

  # Unmutes a user, and cancels the scheduled unmute.
  private_class_method def self.unmute(event, user)
    event.server.channels.each do |channel|
      channel.delete_overwrite(user)
    end
    @mutes[user][0].unschedule
    @mutes.delete(user)
  end
end
