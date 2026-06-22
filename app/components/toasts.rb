# frozen_string_literal: true

class Components::Toasts < Components::Base
  def initialize(flash:)
    @flash = flash
  end

  def view_template
    div(id: "toasts", class: "pointer-events-none fixed inset-x-0 bottom-6 z-50 flex flex-col items-center gap-2 px-4") do
      @flash.each { |level, message| render Components::Toast.new(level:, message:) }
    end
  end
end
