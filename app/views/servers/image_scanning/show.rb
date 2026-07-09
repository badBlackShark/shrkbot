# frozen_string_literal: true

class Views::Servers::ImageScanning::Show < Views::Base
  def initialize(server_configuration:, user:, enabled:)
    @config = server_configuration
    @user = user
    @enabled = enabled
  end

  def view_template
    render Components::PluginShell.new(
      user: @user,
      server_configuration: @config,
      active_key: :image_scanning
    ) do
      render Components::Moderation::ConfigShell.new(
        header: Components::ConfigPageHeader.new(
          icon: "scan",
          title: t(".title"),
          description: t(".description")
        ),
        server_configuration: @config,
        url: server_image_scanning_path(@config.discord_id),
        gate: nil,
        toggle: {
          field: "image_scanning[enabled]",
          enabled: @enabled,
          locked: false
        },
        breadcrumb_extra: t(".title")
      ) do
        div(id: "image_scanning-config") { "" }
      end
    end
  end
end
