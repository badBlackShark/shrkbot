# frozen_string_literal: true

module TwilightStruggle
  class SubscriptionList
    def initialize(server_configuration:, archived: false)
      @server_configuration = server_configuration
      @archived = archived
    end

    def rows
      pairs.select { |tournament, destination| archived?(tournament, destination) == @archived }
    end

    private

    def pairs
      Tournament.includes(:parent).order(:name).map do |tournament|
        [tournament, destinations[tournament.id]]
      end
    end

    def destinations
      @destinations ||= @server_configuration.twilight_struggle_destinations.index_by(&:tournament_id)
    end

    def archived?(tournament, destination)
      tournament.closed_upstream? || destination&.manually_archived? || false
    end
  end
end
