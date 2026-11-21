# frozen_string_literal: true

module Feeds
  class RouteLabels
    def initialize(server_configuration)
      @config = server_configuration
    end

    def channel(channel_id)
      channels[channel_id]
    end

    def channel_text(channel_id)
      channel(channel_id) || channel_missing
    end

    def channel_missing
      I18n.t("components.feeds.route_labels.channel_missing")
    end

    def role_text(role_id)
      name = roles[role_id]
      return I18n.t("components.feeds.route_labels.role_missing") unless name

      name.start_with?("@") ? name : "@#{name}"
    end

    private

    def channels
      @channels ||= ChannelOptions.new(@config).qualified_labels_by_id
    end

    def roles
      @roles ||= ServerRoleOptions.new(@config).names_by_id
    end
  end
end
