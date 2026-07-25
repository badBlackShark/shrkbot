# frozen_string_literal: true

class Components::TwilightStruggle::PingCard < Components::Base
  def initialize(tournament:, inherited:)
    @tournament = tournament
    @inherited = inherited
  end

  def view_template
    render Components::Card.new do
      p(class: "text-sm font-semibold") { t(".label") }
      p(class: "mb-3 mt-0.5 text-sm text-text-secondary") { t(".help") }
      render Components::SegmentedControl.new(
        name: "tournament[ping_players]",
        value: current,
        input_data: {twilight_struggle_preview_target: "ping"},
        options: [
          {value: "", label: t(".inherit")},
          {value: "1", label: t(".mention")},
          {value: "0", label: t(".names")}
        ]
      )
      p(class: "mt-2 text-xs text-text-secondary") { t(".inherits_to", setting: inherited_label) }
    end
  end

  private

  def current
    return "" if @tournament.ping_players.nil?

    @tournament.ping_players ? "1" : "0"
  end

  def inherited_label
    @inherited.ping_players? ? t(".mention") : t(".names")
  end
end
