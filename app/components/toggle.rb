# frozen_string_literal: true

# An on/off switch. Two modes:
#   - standalone (pass `url:`): owns its own form. With `submit_on_change: true`
#     it saves the moment it flips (the dashboard's per-setting toggles).
#   - field (no `url:`): renders just the switch, to sit inside a larger form
#     that saves explicitly (the plugin config pages).
class Components::Toggle < Components::Base
  include Phlex::Rails::Helpers::FormWith

  TRACK = "relative h-6 w-11 flex-none rounded-full bg-ink-300 transition-colors " \
    "after:absolute after:start-0.5 after:top-0.5 after:size-5 after:rounded-full after:bg-white after:shadow " \
    "motion-safe:after:transition-transform peer-checked:bg-brand-500 peer-checked:after:translate-x-5 " \
    "peer-focus-visible:ring-3 peer-focus-visible:ring-[var(--focus-ring)]"

  def initialize(name:, checked:, label:, url: nil, submit_on_change: false, dom_id: nil)
    @name = name.to_s
    @checked = checked
    @label = label
    @url = url
    @submit_on_change = submit_on_change
    @dom_id = dom_id
  end

  def view_template
    if @url
      form_with(url: @url, method: :patch, id: @dom_id, class: "flex-none") { switch }
    else
      switch
    end
  end

  private

  def switch
    input(type: "hidden", name: @name, value: "0", autocomplete: "off")
    label(class: "inline-flex cursor-pointer items-center", aria_label: @label) do
      input(
        type: "checkbox",
        name: @name,
        value: "1",
        checked: @checked,
        class: "peer sr-only",
        data: switch_data
      )
      div(class: TRACK)
    end
  end

  def switch_data
    return {} unless @submit_on_change

    {controller: "toggle", action: "change->toggle#submit"}
  end
end
