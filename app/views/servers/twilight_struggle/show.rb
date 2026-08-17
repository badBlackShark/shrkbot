# frozen_string_literal: true

class Views::Servers::TwilightStruggle::Show < Views::Servers::PluginConfigShow
  def initialize(server_configuration:, user:, enabled:, subscriptions:, archived:, toggleable:)
    super(server_configuration:, user:, enabled:)
    @subscriptions = subscriptions
    @archived = archived
    @toggleable = toggleable
  end

  private

  def plugin_key
    :twilight_struggle
  end

  def icon
    "trophy"
  end

  def url
    server_twilight_struggle_path(@config.discord_id)
  end

  def toggle
    {field: "twilight_struggle[enabled]", enabled: @enabled, locked: !@toggleable, reason: t(".toggle_admin_only")}
  end

  def body
    render Components::TwilightStruggle::ArchiveFilter.new(server_configuration: @config, archived: @archived)
    @subscriptions.empty? ? empty : list
  end

  def empty
    render Components::EmptyState.new(title: t(".empty_title"), body: empty_body) { nil }
  end

  def empty_body
    @archived ? t(".empty_archived") : t(".empty_body")
  end

  def list
    div(class: "mt-5 flex flex-col gap-3") do
      @subscriptions.each do |tournament, destination|
        render Components::TwilightStruggle::TournamentRow.new(
          tournament:,
          destination:,
          server_configuration: @config,
          channel_labels:
        )
      end
    end
  end

  def channel_labels
    @channel_labels ||= ChannelOptions.new(@config).qualified_labels_by_id
  end
end
