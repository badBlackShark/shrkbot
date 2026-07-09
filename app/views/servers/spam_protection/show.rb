# frozen_string_literal: true

class Views::Servers::SpamProtection::Show < Views::Base
  def initialize(server_configuration:, user:, enabled:)
    @config = server_configuration
    @user = user
    @enabled = enabled
  end

  def view_template
    render Components::PluginShell.new(
      user: @user,
      server_configuration: @config,
      active_key: :spam_protection
    ) do
      render Components::Moderation::ConfigShell.new(
        header: Components::ConfigPageHeader.new(
          icon: "megaphone-slash",
          title: t(".title"),
          description: t(".description")
        ),
        server_configuration: @config,
        url: server_spam_protection_path(@config.discord_id),
        gate: nil,
        toggle: {
          field: "spam_protection[enabled]",
          enabled: @enabled,
          locked: false
        },
        breadcrumb_extra: t(".title")
      ) do
        div(id: "spam_protection-config") { "" }
      end
    end
  end
end
