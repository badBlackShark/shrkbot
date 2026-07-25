# frozen_string_literal: true

class Components::TwilightStruggle::PingCard < Components::Base
  def initialize(destination:, inherited:)
    @destination = destination
    @inherited = inherited
  end

  def view_template
    render Components::Card.new do
      p(class: "text-sm font-semibold") { t(".label") }
      p(class: "mb-3 mt-0.5 text-sm text-text-secondary") { t(".help") }
      render Components::SegmentedControl.new(
        name: "destination[ping_players]",
        value: current,
        input_data: {twilight_struggle_preview_target: "ping"},
        options:
      )
      inherit_note
    end
  end

  private

  def parent
    @inherited.inherited_from
  end

  def options
    choices = [{value: "1", label: t(".show")}, {value: "0", label: t(".hide")}]
    return choices unless parent

    [{value: "", label: t(".inherit")}, *choices]
  end

  def current
    return "" if parent && @destination.ping_players.nil?

    resolved? ? "1" : "0"
  end

  def resolved?
    return @destination.ping_players unless @destination.ping_players.nil?

    @inherited.ping_players?
  end

  def inherit_note
    return unless parent

    p(class: "mt-2 text-xs text-text-secondary") do
      t(".inherits_from", parent: parent.name, setting: @inherited.ping_players? ? t(".show") : t(".hide"))
    end
  end
end
