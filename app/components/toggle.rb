# frozen_string_literal: true

class Components::Toggle < Components::Base
  include Phlex::Rails::Helpers::FormWith

  COMMON = "flex-none rounded-full bg-border-strong transition-colors after:absolute after:start-0.5 after:top-0.5 " \
    "after:rounded-full after:bg-white after:shadow motion-safe:after:transition-transform peer-checked:bg-accent-fill " \
    "peer-focus-visible:ring-3 peer-focus-visible:ring-[var(--focus-ring)]"

  SIZES = {
    md: "relative h-6 w-11 after:size-5 peer-checked:after:translate-x-5",
    mini: "relative h-[18px] w-8 after:size-3.5 peer-checked:after:translate-x-3.5"
  }.freeze

  def initialize(checked:, label:, name: nil, size: :md, url: nil, submit_on_change: false, dom_id: nil, disabled: false, data: {}, form: nil)
    @name = name&.to_s
    @checked = checked
    @label = label
    @size = size
    @url = url
    @submit_on_change = submit_on_change
    @dom_id = dom_id
    @disabled = disabled
    @data = data
    @form = form
  end

  def view_template
    if @url && !@disabled
      # autocomplete: off so the browser doesn't restore the checkbox to its
      # pre-reload state and override the server-rendered value.
      form_with(url: @url, method: :patch, id: @dom_id, class: "flex-none", autocomplete: "off") { switch }
    else
      switch
    end
  end

  private

  def switch
    input(type: "hidden", name: @name, value: "0", autocomplete: "off", form: @form) if @name && !@disabled
    label(class: "inline-flex items-center #{@disabled ? "cursor-not-allowed opacity-60" : "cursor-pointer"}", aria_label: @label) do
      input(
        type: "checkbox",
        name: @name,
        value: "1",
        checked: @checked,
        disabled: @disabled,
        autocomplete: "off",
        class: "peer sr-only",
        data: switch_data,
        form: @form
      )
      div(class: "#{SIZES.fetch(@size)} #{COMMON}")
    end
  end

  def switch_data
    base = @submit_on_change ? {controller: "toggle", action: "change->toggle#submit"} : {}
    base.merge(@data)
  end
end
