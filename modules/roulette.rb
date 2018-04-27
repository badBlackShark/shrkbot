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

    if event.user.id == 94558130305765376
      "I couldn't ever let you shoot yourself. #{Emojis.name_to_emoji('heart')}"
    elsif outcome
      event.respond "Unlucky. #{event.user.mention} shoots themself in the head, and dies."
      Moderation.mute(event, event.user, '1m', 'Died while playing roulette.')
      load_revolver(event.server.id)
      @position[event.server.id] = 0
      event.respond 'The revolver has been reloaded.'
    else
      @position[event.server.id] += 1
      "The revolver clicks, and #{event.user.mention} survives. Congratulations."
    end
  end

  def self.load_revolver(id)
    @revolver[id] = [true, false, false, false, false, false].shuffle
    @position[id] = 0
  end

  def self.start_scheduler(server)
    @reloading[server.id] = @scheduler.every('30m', job: true) do
      unless @position[server.id] == 0
        load_revolver(server.id)
        LOGGER.log(server, 'People were too scared to pull the trigger again. '\
                           'The revolver has been reloaded.')
      end
    end
  end
end
