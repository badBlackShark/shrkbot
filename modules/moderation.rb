require 'rufus-scheduler'

# Tools for moderating a server
module Moderation
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer
  extend self

  @scheduler = Rufus::Scheduler.new
  # User => {job: <the job object>, time: <time of unmute>, reason: <reason for the mute>}
  @mutes = {}
  @deny = nil

  def init
    DB.create_table(
      'shrk_muted_roles',
      server: :bigint,
      role: :bigint
    )

    # This gets stored, so the Permissions object doesn't have to be created so often.
    @deny = Discordrb::Permissions.new
    @deny.can_send_messages = true
    @deny.can_speak = true
    SHRK.servers.each_value do |server|
      Thread.new do
        update_muted_role(server)
      end
    end
  end

  channel_create do |event|
    unless event.channel.private?
      event.channel.define_overwrite(muted_role(event.server), 0, @deny, reason: 'Added overwrite for bot mutes.')
    end
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'refreshMutedRole',
    description: 'Allows for a refresh of the muted role, e.g. when it was accidentally deleted.'
  }
  command :refreshmutedrole, attrs do |event|
    update_muted_role(event.server)
    Reactions.confirm(event.message)
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'mute <userMentions> <duration> <reason>',
    description: 'Mutes all users mentioned in the command for the duration given. '\
                 "Order doesn't matter, duration and reason are optional and have default values.\n"\
                 "Supported time formats: s, m, d, w, M, y. Mixing formats (e.g. 1d10h) is supported.\n"\
                 "**WARNING**: When the bot restarts, it won't unmute currently muted users!",
    min_args: 1
  }
  command :mute, attrs do |event, *args|
    users = event.message.mentions
    next 'Please mention at least one user to be muted.' if users.empty?
    # Rejects the mentions and everything that doesn't fit the time format from the list of args.
    time = args.reject { |x| x =~ /<@!?(\d+)>/ || x !~ /^((\d+)[smhdwMy]{1})+$/ }.join
    # Defaults to one day if it couldn't find a legit time.
    time = '1d' if time.empty?

    reason = args.reject { |x| x =~ /<@!?(\d+)>/ || x =~ /^((\d+)[smhdwMy]{1})+$/ }.join(' ')
    reason = '`No reason provided`' if reason.empty?

    mute(event, users, time, reason)
    Reactions.confirm(event.message)
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
    Reactions.confirm(event.message)
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
        value: "#{info[:time].strftime("Muted until #{TIME_FORMAT}")}\n**Reason:** #{info[:reason]}"
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

  attrs = {
    permission_level: 2,
    permission_message: false
  }
  command :prunemutes, attrs do |event|
    f = File.open('mute_dump.txt', 'w+')
    f.write(@mutes)
    f.close
    SHRK.user(94558130305765376).pm.send_file(File.open('mute_dump.txt'))
    @mutes.each_pair do |user, info|
      @mutes.delete(user) if info[:time].nil?
    end
    'Done.'
  end

  def mute(event, users, time, reason, logging: true)
    deny = Discordrb::Permissions.new
    deny.can_send_messages = true
    deny.can_speak = true

    users.each do |user|
      user.on(event.server).add_role(muted_role(event.server))
      schedule_unmute(event, user, time)
      @mutes[user][:reason] = reason
    end

    if logging
      LOGGER.log(event.server, "Successfully muted `#{users.map(&:distinct).join('`, `')}` until "\
                "#{@mutes[users.first][:time].strftime(TIME_FORMAT)}. Reason: **#{reason}**")
    end
  end

  private

  def update_muted_role(server)
    # This is an Array of Hashes, but actually just one Hash, which is the one mapping the
    # server ID of the requested server to the role ID we want, so this can just be merged.
    role_id = DB.select_rows(:shrk_muted_roles, :server, server.id).inject(:merge)&.fetch(:role)
    return if role_id && server.role(role_id)
    role = create_muted_role(server)
    DB.update_row(:shrk_muted_roles, [server.id, role.id])
    server.channels.each do |channel|
      channel.define_overwrite(role, 0, @deny, reason: 'Added overwrite for bot mutes.')
    end
  end

  def create_muted_role(server)
    server.create_role(
      name: 'muted',
      permissions: 0,
      reason: 'Added the role required for bot mutes.'
    )
  end

  # Schedules the unmute for a user
  def schedule_unmute(event, user, time)
    @mutes[user][:job].unschedule if @mutes[user]

    @mutes[user] = {}
    @mutes[user][:job] = @scheduler.in(time, job: true) do
      user.pm("You're no longer muted for `#{@mutes[user][:reason]}` in **#{event.server.name}**.")
      unmute(event, user)
    end
    @mutes[user][:time] = @mutes[user][:job].next_time
  end

  # Unmutes a user, and cancels the scheduled unmute.
  def unmute(event, user)
    user.on(event.server).remove_role(muted_role(event.server))
    @mutes[user][:job].unschedule
    @mutes.delete(user)
  end

  # Gets the the muted role on the given server
  def muted_role(server)
    # This is an Array of Hashes, but actually just one Hash, which is the one mapping the
    # server ID of the requested server to the role ID we want, so this can just be merged.
    server.role(DB.select_rows(:shrk_muted_roles, :server, server.id).inject(:merge)[:role])
  end
end
