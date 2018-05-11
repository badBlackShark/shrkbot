require 'rufus-scheduler'

# Simulates a revolver with 6 shots on a per-server basis.
# Revolver times out if people wait too long to play.
module Roulette
  extend Discordrb::Commands::CommandContainer

  # Server => chamber
  @revolver = {}
  # Server => int
  @position = {}
  # Server => job
  @reloading = {}

  @scheduler = Rufus::Scheduler.new

  command :roulette do |event|
    outcome = @revolver[event.server.id][@position[event.server.id]]

    # Reset the timeout for the revolver
    @reloading[event.server.id]&.unschedule
    start_scheduler(event.server)

    if SHRK.permission?(event.user, 2, event.server)
      WH.send(
        event.channel.id,
        "I couldn't ever let you shoot yourself.",
        username: "Don't do it!",
        avatar_url: Icons.name_to_link(:heart)
      )
    elsif outcome
      pos = @position[event.server.id] + 1
      load_revolver(event.server.id)
      embed = Discordrb::Webhooks::Embed.new
      embed.footer = {text: "Unlucky. #{event.user.name} has died on shot ##{pos}."}
      embed.colour = 12648448
      WH.send(
        event.channel.id,
        nil,
        username: 'The revolver has been reloaded',
        avatar_url: Icons.name_to_link("revolver_d#{pos}".to_sym),
        embed: embed
      )
      Moderation.mute(event, [event.user], '1m', 'Died while playing roulette.', logging: false)
      nil
    else
      @position[event.server.id] += 1
      embed = Discordrb::Webhooks::Embed.new
      embed.footer = {text: "#{event.user.name} survived shot ##{@position[event.server.id]}"}
      embed.colour = 171520
      WH.send(
        event.channel.id,
        nil,
        username: "Congratulations!",
        avatar_url: Icons.name_to_link("revolver_#{@position[event.server.id]}".to_sym),
        embed: embed
      )
    end
  end

  def self.load_revolver(id)
    @revolver[id] = [true, false, false, false, false, false].shuffle
    @position[id] = 0
  end

  def self.start_scheduler(server)
    @reloading[server.id] = @scheduler.every('15m', job: true) do
      unless @position[server.id].zero?
        load_revolver(server.id)
        LOGGER.log(server, 'People were too scared to pull the trigger again. '\
                           'The revolver has been reloaded.')
      end
    end
  end
end
