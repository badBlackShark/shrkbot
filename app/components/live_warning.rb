# frozen_string_literal: true

class Components::LiveWarning < Components::Base
  def initialize(fields:, rule:, shown:, list: [], **attrs)
    @fields = fields
    @rule = rule
    @shown = shown
    @list = list
    @attrs = attrs
  end

  def view_template(&)
    render Components::Callout.new(variant: :warning, hidden: !@shown, data: wiring, **@attrs, &)
  end

  private

  def wiring
    {
      controller: "live-warning",
      live_warning_fields_value: @fields.to_json,
      live_warning_rule_value: @rule,
      live_warning_list_value: @list.to_json
    }
  end
end
