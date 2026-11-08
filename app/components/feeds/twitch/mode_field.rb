# frozen_string_literal: true

class Components::Feeds::Twitch::ModeField < Components::Base
  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    div(data: {controller: "option-panels"}) do
      render Components::FieldLabel.new { label }
      render Components::SegmentedControl.new(
        name: "subscription[#{setting}]",
        value: selected,
        options: modes.map { |mode| {value: mode, label: mode_label(mode)} },
        input_data: {action: "input->option-panels#show"}
      )
      modes.each { |mode| panel(mode) }
    end
  end

  private

  def selected
    @subscription.settings.public_send(setting)
  end

  def panel(mode)
    render panel_class.new(mode:, card: card(mode), hidden: mode != selected)
  end

  def samples
    @samples ||= ::Feeds::Twitch::PreviewSamples.new(
      watch_name: @subscription.watch.name,
      event_type: ::Integrations::Twitch::StreamStarted.name
    )
  end
end
