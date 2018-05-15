require 'rufus-scheduler'

# Simulates a revolver with 6 shots on a per-server basis.
# Revolver times out if people wait too long to play.
module Roulette
  extend Discordrb::Commands::CommandContainer

  # ServerID => Role
  @survivor_role = {}

  def self.init
    DB.create_table(
      'shrk_roulette',
      user: :bigint,
      plays: Integer,
      streak: Integer,
      highscore: Integer
    )

    # Converts the array of hashes to an ID => Hash hash.
    @data = DB.read_all(:shrk_roulette).map { |e| [e[:user], e] }.to_h

    SHRK.servers.each_value do |server|
      role = server.roles.find { |r| r.name.eql?('Survivor') }
      unless role
        role = server.create_role(
          name: 'Survivor',
          colour: 13938487,
          reason: 'Role to award to especially lucky roulette players.'
        )
      end
      @survivor_role[server.id] = role
      @messages[server.id] = []
    end
  end

  # Server => chamber
  @revolver = {}
  # Server => int
  @position = {}
  # Server => job
  @reloading = {}
  # Contains all user info stored in the database.
  @data = {}
  # Contains all of the bots roulette messages, queued for deletion. Server => Messages
  @messages = {}

  @scheduler = Rufus::Scheduler.new

  attrs = {
    usage: 'roulette',
    description: 'You have a 1/6 chance to die. Dying mutes you for 1 minute.'
  }
  command :roulette, attrs do |event, flag|
    # Just so nothing is nil
    init_user_data(event.user.id)
    @data[event.user.id][:plays] += 1
    @data[event.user.id][:modified] = true

    outcome = @revolver[event.server.id][@position[event.server.id]]

    # Reset the timeout for the revolver
    @reloading[event.server.id]&.unschedule
    start_scheduler(event.server)

    if SHRK.permission?(event.user, 2, event.server) && !flag.eql?('--shark')
      msg = WH.send(
        event.channel.id,
        "I couldn't ever let you shoot yourself.",
        username: "Don't do it!",
        avatar_url: Icons.name_to_link(:heart)
      )
      msg = JSON.parse(msg)['id']
      queue_for_deletion(
        event.server.id, [
          {id: msg, channel: event.channel.id},
          {id: event.message.id, channel: event.channel.id}
        ]
      )
      nil
    elsif outcome
      pos = @position[event.server.id] + 1
      load_revolver(event.server.id)
      Moderation.mute(event, [event.user], '1m', 'Died while playing roulette.', logging: false)
      embed = Discordrb::Webhooks::Embed.new
      embed.footer = {
        text: "Unlucky. #{event.user.name} has died on shot ##{pos}.\n"\
               "You just ended your streak of #{@data[event.user.id][:streak]}."
      }
      embed.colour = 12648448
      msg = WH.send(
        event.channel.id,
        nil,
        username: 'Unlucky!',
        avatar_url: Icons.name_to_link("revolver_d#{pos}".to_sym),
        embed: embed
      )
      @data[event.user.id][:streak] = 0
      msg = JSON.parse(msg)['id']
      queue_for_deletion(
        event.server.id, [
          {id: msg, channel: event.channel.id},
          {id: event.message.id, channel: event.channel.id}
        ]
      )
      delete_round(event.server)
      nil
    else
      @position[event.server.id] += 1
      @data[event.user.id][:streak] += 1
      embed = Discordrb::Webhooks::Embed.new
      if @data[event.user.id][:highscore] < @data[event.user.id][:streak]
        @data[event.user.id][:highscore] += 1
        if @data[event.user.id][:highscore] == 20
          award_survivor_role(event.user.id)
          embed.description = '**Survior role awarded!**'
        end
        embed.title = 'New highscore!'
      end
      embed.footer = {
        text: "#{event.user.name} survived shot ##{@position[event.server.id]}.\n"\
               "Your current streak is #{@data[event.user.id][:streak]}."
      }
      embed.colour = 171520
      msg = WH.send(
        event.channel.id,
        nil,
        username: 'Congratulations!',
        avatar_url: Icons.name_to_link("revolver_#{@position[event.server.id]}".to_sym),
        embed: embed
      )
      msg = JSON.parse(msg)['id']
      queue_for_deletion(
        event.server.id, [
          {id: msg, channel: event.channel.id},
          {id: event.message.id, channel: event.channel.id}
        ]
      )
      nil
    end
  end

  attrs = {
    usage: 'leaderboard',
    description: 'Shows a leaderboard of roulette highscores.'
  }
  command :leaderboard, attrs do |event|
    embed = Discordrb::Webhooks::Embed.new
    # Don't select more than the top 12. Reverse because sort sorts ascending.
    @data.sort_by { |_, e| e[:highscore] }.reverse[0, 12].each do |entry|
      user = SHRK.user(entry.first).distinct
      embed.add_field(
        name: "**#{user}**",
        value: "Best streak: *#{entry[1][:highscore]}*",
        inline: true
      )
    end
    embed.colour = 13938487
    embed.timestamp = Time.now
    WH.send(
      event.channel.id,
      nil,
      username: 'Roulette leaderboard',
      avatar_url: Icons.name_to_link(:leaderboard),
      embed: embed
    )
    nil
  end

  attrs = {
    usage: 'stats',
    description: 'Shows your current roulette stats.'
  }
  command :stats, attrs do |event|
    init_user_data(event.user.id)
    embed = Discordrb::Webhooks::Embed.new
    embed.author = {
      name: "Stats for #{event.user.distinct}",
      icon_url: event.user.avatar_url
    }
    stats = ''
    stats << "• **Total number of plays**: #{@data[event.user.id][:plays]}\n\n"
    stats << "• **Current streak:** #{@data[event.user.id][:streak]}\n\n"
    stats << "• **Best streak:** #{@data[event.user.id][:highscore]}\n\n"

    embed.description = stats
    embed.colour = @data[event.user.id][:highscore] >= 20 ? 13938487 : 12632256
    embed.timestamp = Time.now

    WH.send(
      event.channel.id,
      nil,
      username: 'Roulette stats',
      avatar_url: Icons.name_to_link(:chart),
      embed: embed
    )
    nil
  end

  attrs = {
    permission_level: 2,
    permission_message: false,
    usage: 'writeToDB',
    description: 'Writes modified rows of @data to the database.'
  }
  command :writetodb, attrs do |event|
    write_to_db
    Reactions.confirm(event.message)
  end

  # Stores all modified rows in the database.
  def self.write_to_db
    @data.each_pair do |id, h|
      if h[:modified]
        # The :modified attribute doesn't need to be written into the database.
        DB.update_row(:shrk_roulette, [id, h[:plays], h[:streak], h[:highscore]])
        h[:modified] = false
      end
    end
  end

  private_class_method def self.queue_for_deletion(server_id, msgs)
    @messages[server_id].concat(msgs)
  end

  private_class_method def self.award_survivor_role(id)
    SHRK.servers.each_value do |server|
      SHRK.user(id).on(server)&.add_role(@survivor_role[server.id])
    end
  end

  # Deletes the roulette call, as well as the bot's response
  private_class_method def self.delete_round(server)
    # Creates a hash channel_id => Array of message IDs in that channel.
    del = @messages[server.id].group_by { |h| h[:channel] }.each_value { |e| e.map! { |h| h[:id] } }
    @messages[server.id] = []
    sleep 2
    del.each_pair { |channel, msgs| SHRK.channel(channel)&.delete_messages(msgs) }
  end

  # Initialize with default values, so nothing we want to increment can be nil
  private_class_method def self.init_user_data(id)
    @data[id] ||= {}
    @data[id][:plays] ||= 0
    @data[id][:streak] ||= 0
    @data[id][:highscore] ||= 0
  end

  def self.load_revolver(id)
    @revolver[id] = [true, false, false, false, false, false].shuffle
    @position[id] = 0
  end

  def self.start_scheduler(server)
    @reloading[server.id] = @scheduler.every('15m', job: true) do
      unless @position[server.id].zero?
        load_revolver(server.id)
        delete_round(server)
        LOGGER.log(server, 'People were too scared to pull the trigger again. The revolver has been reloaded.')
      end
    end
  end
end
