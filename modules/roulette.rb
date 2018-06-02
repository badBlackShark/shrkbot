require 'rufus-scheduler'

# Simulates a revolver with 6 shots on a per-server basis.
# Revolver times out if people wait too long to play.
module Roulette
  extend Discordrb::Commands::CommandContainer
  extend self

  # ServerID => Role
  @survivor_role = {}

  def init
    DB.create_table(
      'shrk_roulette',
      user: :bigint,
      server: :bigint,
      plays: Integer,
      streak: Integer,
      highscore: Integer,
      deaths: Integer
    )

    # {User => {Server => {Attributes}}}
    @data = DB.read_all(:shrk_roulette).group_by { |e| e[:user] }.transform_values { |v| v.map { |e| [e[:server], e] }.to_h }

    SHRK.servers.each_value do |server|
      role = server.roles.find { |r| r.name.eql?('Survivor') }
      unless role
        # extract
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
    init_user_data(event.user.id, event.server.id)
    @data[event.user.id][event.server.id][:plays] += 1
    @data[event.user.id][event.server.id][:modified] = true

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
        text: "Unlucky. #{event.user.name} has died on shot ##{pos}, and ended "\
               "their streak of #{@data[event.user.id][event.server.id][:streak]}."
      }
      embed.colour = 12648448
      msg = WH.send(
        event.channel.id,
        nil,
        username: 'Unlucky!',
        avatar_url: Icons.name_to_link("revolver_d#{pos}".to_sym),
        embed: embed
      )
      @data[event.user.id][event.server.id][:deaths] += 1
      @data[event.user.id][event.server.id][:streak] = 0
      msg = JSON.parse(msg)['id']
      queue_for_deletion(
        event.server.id, [
          {id: event.message.id, channel: event.channel.id}
        ]
      )
      delete_round(event.server)
      nil
    else
      @position[event.server.id] += 1
      @data[event.user.id][event.server.id][:streak] += 1
      embed = Discordrb::Webhooks::Embed.new
      if @data[event.user.id][event.server.id][:highscore] < @data[event.user.id][event.server.id][:streak]
        @data[event.user.id][event.server.id][:highscore] += 1
        if @data[event.user.id][event.server.id][:highscore] == 20
          award_survivor_role(event.user.id)
          embed.description = '**Survior role awarded!**'
        end
        embed.title = 'New highscore!'
      end
      embed.footer = {
        text: "#{event.user.name} survived shot ##{@position[event.server.id]}.\n"\
               "Your current streak is #{@data[event.user.id][event.server.id][:streak]}."
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
    usage: 'leaderboard <--global>',
    description: "Shows a leaderboard of top 10 roulette highscores, plays and deaths for this server.\n"\
                 'If the `--global` flag is set, the leaderboard for all servers will be displayed.'
  }
  command :leaderboard, attrs do |event, flag = ''|
    global = flag.casecmp?('--global')

    embed = Discordrb::Webhooks::Embed.new
    content = global ? global_board : server_board(event.server.id)

    embed.add_field(
      name: '__Top 10 (highscore)__',
      value: content[:highscores],
      inline: true
    )
    embed.add_field(
      name: '__Top 10 (plays)__',
      value: content[:plays],
      inline: true
    )
    embed.add_field(
      name: '__Top 10 (deaths)__',
      value: content[:deaths],
      inline: true
    )
    embed.colour = 13938487
    embed.timestamp = Time.now
    embed.footer = {text: global ? 'Showing global leaderboard.' : 'Showing leaderboard for this server.'}
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
    usage: 'stats <--server>',
    description: "Shows your current roulette stats for this server.\n"\
                 'If the `--global` flag is set, your stats for all servers will be displayed.'
  }
  command :stats, attrs do |event, flag = ''|
    global = flag.casecmp?('--global')
    init_user_data(event.user.id, event.server.id)
    embed = Discordrb::Webhooks::Embed.new
    embed.author = {
      name: "Stats for #{event.user.distinct}",
      icon_url: event.user.avatar_url
    }
    stats = global ? global_stats(event.user.id) : server_stats(event.user.id, event.server.id)

    description = ''
    description << "• Total number of plays: **#{stats[:plays]}**\n"
    description << "• Total number of deaths: **#{stats[:deaths]}**\n"
    description << "• Current#{global ? ' hightest': ''} streak: **#{stats[:streak]}**\n"
    description << "• Best streak: **#{stats[:highscore]}**"

    embed.description = description
    embed.colour = stats[:highscore] >= 20 ? 13938487 : 12632256
    embed.timestamp = Time.now
    embed.footer = {text: global ? 'Showing global stats.' : 'Showing your stats for this server.'}

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
  def write_to_db
    @data.each_pair do |user_id, h|
      h.each_pair do |server_id, a|
        if a[:modified]
          # The :modified attribute doesn't need to be written into the database.
          DB.update_row_double_key(
            :shrk_roulette,
            [user_id, server_id, a[:plays], a[:streak], a[:highscore], a[:deaths]]
          )
          a[:modified] = false
        end
      end
    end
  end

  private

  def global_board
    # Don't select more than the top 10. Reverse because sort sorts ascending.
    highscores = @data.transform_values { |e| e.values.max_by { |v| v[:highscore] } }
                      .sort_by { |e, f| f[:highscore] }.reverse[0, 10]
    deaths = @data.transform_values { |e| e.values.max_by { |v| v[:deaths] } }
                  .sort_by { |e, f| f[:deaths] }.reverse[0, 10]
    plays = @data.transform_values { |e| e.values.max_by { |v| v[:plays] } }
                 .sort_by { |e, f| f[:plays] }.reverse[0, 10]

    highscores.map! { |user, e| "• #{SHRK.user(user).distinct}: **#{e[:highscore]}**  \u200b\n" }
    deaths.map! { |user, e| "• #{SHRK.user(user).distinct}: **#{e[:deaths]}**\n" }
    plays.map! { |user, e| "• #{SHRK.user(user).distinct}: **#{e[:plays]}**  \u200b\n" }

    {highscores: highscores.join(), deaths: deaths.join(), plays: plays.join()}
  end

  def server_board(server_id)
    # Don't select more than the top 10. Reverse because sort sorts ascending.
    highscores = @data.select { |e, h| h.keys.include?(server_id) }
                      .transform_values { |e| e.select { |h, _| h == server_id } }
                      .sort_by { |e, f| f[server_id][:highscore] }.reverse[0, 10]

    deaths = @data.select { |e, h| h.keys.include?(server_id) }
                  .transform_values { |e| e.select { |h, _| h == server_id } }
                  .sort_by { |e, f| f[server_id][:deaths] }.reverse[0, 10]

    plays = @data.select { |e, h| h.keys.include?(server_id) }
                 .transform_values { |e| e.select { |h, _| h == server_id } }
                 .sort_by { |e, f| f[server_id][:plays] }.reverse[0, 10]

    highscores.map! { |user, e| "• #{SHRK.user(user).distinct}: **#{e[server_id][:highscore]}**  \u200b\n" }
    deaths.map! { |user, e| "• #{SHRK.user(user).distinct}: **#{e[server_id][:deaths]}**\n" }
    plays.map! { |user, e| "• #{SHRK.user(user).distinct}: **#{e[server_id][:plays]}**  \u200b\n" }

    {highscores: highscores.join(), deaths: deaths.join(), plays: plays.join()}
  end

  def global_stats(user_id)
    {
      plays: @data[user_id].values.reduce(0) { |sum, e| sum += e[:plays] },
      deaths: @data[user_id].values.reduce(0) { |sum, e| sum += e[:deaths] },
      streak: @data[user_id].values.max_by { |v| v[:streak] }[:streak],
      highscore: @data[user_id].values.max_by { |v| v[:highscore] }[:highscore]
    }
  end

  def server_stats(user_id, server_id)
    {
      plays: @data[user_id][server_id][:plays],
      deaths: @data[user_id][server_id][:deaths],
      streak: @data[user_id][server_id][:streak],
      highscore: @data[user_id][server_id][:highscore]
    }
  end

  def queue_for_deletion(server_id, msgs)
    @messages[server_id].concat(msgs)
  end

  # Deletes the roulette call, as well as the bot's response
  def delete_round(server)
    # Creates a hash channel_id => Array of message IDs in that channel.
    del = @messages[server.id].group_by { |h| h[:channel] }.each_value { |e| e.map! { |h| h[:id] } }
    @messages[server.id] = []
    sleep 2
    del.each_pair do |channel, msgs|
      if msgs.size == 1
        SHRK.channel(channel)&.delete_message(msgs.first)
      else
        SHRK.channel(channel)&.delete_messages(msgs)
      end
    end
  end

  def award_survivor_role(id)
    SHRK.servers.each_value do |server|
      SHRK.user(id).on(server)&.add_role(@survivor_role[server.id])
    end
  end

  # Initialize with default values, so nothing we want to increment can be nil
  def init_user_data(user_id, server_id)
    @data[user_id] ||= {}
    @data[user_id][server_id] ||= {}
    @data[user_id][server_id][:plays] ||= 0
    @data[user_id][server_id][:deaths] ||= 0
    @data[user_id][server_id][:streak] ||= 0
    @data[user_id][server_id][:highscore] ||= 0
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
