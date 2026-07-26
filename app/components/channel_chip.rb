# frozen_string_literal: true

class Components::ChannelChip < Components::Base
  def initialize(label:)
    @label = label
  end

  def view_template
    span(class: "inline-flex items-center rounded-control border border-border-default bg-surface-sunken px-2 py-1 text-xs font-medium text-text-secondary") { @label }
  end
end
