class Views::Servers::Logging::Show < Views::Base
  def initialize(server_configuration:, user:, enabled:)
    @config = server_configuration
    @user = user
    @enabled = enabled
  end

  def view_template
    render Components::AppShell.new(user: @user) do
      render Components::ConfigPage.new(
        icon: "document-text",
        title: t(".title"),
        description: t(".description"),
        dashboard_path: server_path(@config.discord_id)
      ) do
        render Components::Logging::ConfigForm.new(server_configuration: @config, enabled: @enabled)
      end
    end
  end
end
