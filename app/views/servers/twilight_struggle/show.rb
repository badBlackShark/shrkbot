# frozen_string_literal: true

class Views::Servers::TwilightStruggle::Show < Views::Base
  def initialize(server_configuration:, user:, enabled:, subscriptions:, archived:, toggleable:)
    @config = server_configuration
    @user = user
    @enabled = enabled
    @subscriptions = subscriptions
    @archived = archived
    @toggleable = toggleable
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: :twilight_struggle) do
      render Components::ConfigPage.new(
        header: Components::ConfigPageHeader.new(icon: "trophy", title: t(".title"), description: t(".description")),
        server_configuration: @config,
        url: server_twilight_struggle_path(@config.discord_id),
        toggle: {field: "twilight_struggle[enabled]", enabled: @enabled, locked: !@toggleable, reason: t(".toggle_admin_only")},
        gate: {type: :enable, message: t(".gate_message")}
      ) do
        render Components::TwilightStruggle::ArchiveFilter.new(server_configuration: @config, archived: @archived)
        @subscriptions.empty? ? empty : list
      end
    end
  end

  private

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
