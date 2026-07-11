# frozen_string_literal: true

class AuthorizedNotifications
  def initialize(manageable_ids:, server_id: nil)
    @manageable_ids = manageable_ids
    @server_id = server_id
  end

  def groups
    if @server_id
      return [] unless @manageable_ids.include?(@server_id.to_i)

      config = ServerConfiguration.find_by(discord_id: @server_id)
      return [] unless config

      [[config, scoped.where(server_configuration: config).includes(:server_configuration).to_a]]
    else
      configs = ServerConfiguration
        .where(discord_id: @manageable_ids)
        .order(:name)
        .index_by(&:id)

      scoped
        .includes(:server_configuration)
        .group_by(&:server_configuration_id)
        .filter_map do |config_id, notifications|
          config = configs[config_id]
          next unless config

          [config, notifications]
        end
        .sort_by { |config, _| config.name.to_s }
    end
  end

  def unread_count
    base_relation.unread.count
  end

  def scoped
    base_relation
  end

  private

  def base_relation
    Notification
      .active
      .recent
      .joins(:server_configuration)
      .where(server_configurations: {discord_id: @manageable_ids})
  end
end
