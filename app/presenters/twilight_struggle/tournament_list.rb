# frozen_string_literal: true

module TwilightStruggle
  class TournamentList
    def initialize(server_configurations:, owner:, archived: false)
      @server_configurations = server_configurations
      @owner = owner
      @archived = archived
    end

    def all
      return scope if @owner

      scope.where(server_configuration: @server_configurations).or(scope.unclaimed)
    end

    def configurable
      all.where.not(server_configuration_id: nil)
    end

    private

    def scope
      base = Tournament.includes(:parent, :server_configuration).order(:name)
      @archived ? base.archived : base.unarchived
    end
  end
end
