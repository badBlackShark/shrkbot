# frozen_string_literal: true

class Components::Feeds::Twitch::EndModeField < Components::Base
  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    div(data: {controller: "option-panels"}) do
      render Components::FieldLabel.new { t(".label") }
      render Components::SegmentedControl.new(
        name: "subscription[live_end_mode]",
        value: selected,
        options: ::Feeds::Twitch::Settings::LIVE_END_MODES.map { |mode| {value: mode, label: t(".modes.#{mode}")} },
        input_data: {action: "input->option-panels#show"}
      )
      ::Feeds::Twitch::Settings::LIVE_END_MODES.each { |mode| panel(mode) }
    end
  end

  private

  def selected
    @subscription.settings.live_end_mode
  end

  def panel(mode)
    render Components::Feeds::Twitch::EndModePanel.new(mode:, card: samples.end_mode_card(mode), hidden: mode != selected)
  end

  def samples
    @samples ||= ::Feeds::Twitch::PreviewSamples.new(
      watch_name: @subscription.watch.name,
      event_type: ::Integrations::Twitch::StreamStarted.name
    )
  end
end
