# frozen_string_literal: true

class Components::PluginStatusBadge < Components::Base
  def initialize(configured:, locked: false)
    @configured = configured
    @locked = locked
  end

  def view_template
    if @locked
      render Components::Badge.new(variant: :copper) { t(".always_on") }
    elsif !@configured
      render Components::Badge.new(variant: :warning, dot: true) { t(".needs_setup") }
    end
  end
end
