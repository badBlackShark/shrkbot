# frozen_string_literal: true

module Finders
  class AuthorizedNotifications
    def initialize(manageable_ids:, server_id: nil)
      @manageable_ids = manageable_ids
      @server_id = server_id
    end

    def groups
      return single_server_group if @server_id

      grouped_by_server
    end

    def unread_count
      base_relation.unread.count
    end

    def scoped
      base_relation
    end

    private

    def single_server_group
      return [] unless @manageable_ids.include?(@server_id.to_i)

      config = ServerConfiguration.find_by(discord_id: @server_id)
      return [] unless config

      [[config, scoped.where(server_configuration: config).includes(:server_configuration).to_a]]
    end

    def grouped_by_server
      scoped
        .includes(:server_configuration)
        .group_by(&:server_configuration)
        .sort_by { |config, _| config.name.to_s }
    end

    def base_relation
      Notification
        .active
        .recent
        .joins(:server_configuration)
        .where(server_configurations: {discord_id: @manageable_ids})
    end
  end
end
