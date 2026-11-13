# frozen_string_literal: true

class Components::Reminders::ConfigForm < Components::Base
  def initialize(server_configuration:)
    @config = server_configuration
  end

  def view_template
    render Components::ConfigSections.new(key: "reminders") do
      force_dm_card
    end
  end

  private

  def force_dm_card
    render Components::ToggleCard.new(
      name: "reminders[force_dm_reminders]",
      checked: @config.force_dm_reminders,
      label: t(".force_dm.label")
    )
  end
end
