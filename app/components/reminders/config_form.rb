# frozen_string_literal: true

class Components::Reminders::ConfigForm < Components::Base
  def initialize(server_configuration:)
    @config = server_configuration
  end

  def view_template
    div(id: "reminders-config", class: "flex flex-col gap-5") do
      force_dm_card
      command_callout
    end
  end

  private

  def force_dm_card
    render Components::Card.new(class: "flex items-center gap-4") do
      div(class: "flex-1") do
        p(class: "text-sm font-semibold") { t(".force_dm.label") }
        p(class: "mt-0.5 text-sm text-text-secondary") { t(".force_dm.help") }
      end
      render Components::Toggle.new(
        name: "reminders[force_dm_reminders]",
        checked: @config.force_dm_reminders,
        label: t(".force_dm.label")
      )
    end
  end

  def command_callout
    render Components::Callout.new(variant: :info) do
      plain t(".callout.before")
      whitespace
      code(class: "rounded bg-surface-sunken px-1.5 py-0.5 font-mono text-xs text-accent-soft-fg") { "/remind" }
      whitespace
      plain t(".callout.after")
    end
  end
end
