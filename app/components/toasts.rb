# frozen_string_literal: true

class Components::Toasts < Components::Base
  LEVELS = {
    "alert" => {icon: "exclamation-triangle", tone: "border-danger/30 bg-danger-soft text-danger"},
    "notice" => {icon: "check-circle", tone: "border-success/30 bg-success-soft text-success"}
  }.freeze

  def initialize(flash:)
    @flash = flash
  end

  def view_template
    return if @flash.none?

    div(class: "pointer-events-none fixed inset-x-0 bottom-6 z-50 flex flex-col items-center gap-2 px-4") do
      @flash.each { |level, message| toast(level, message) }
    end
  end

  private

  def toast(level, message)
    style = LEVELS.fetch(level.to_s, LEVELS["notice"])
    div(
      role: "status",
      data: {controller: "toast"},
      class: "anim-fade pointer-events-auto flex items-center gap-2.5 rounded-lg border px-4 py-2.5 text-sm font-medium shadow-lg #{style[:tone]}"
    ) do
      render Components::Icon.new(style[:icon], class: "size-4 flex-none")
      span { message }
      button(
        type: "button",
        aria_label: "Dismiss",
        data: {action: "toast#dismiss"},
        class: "-mr-1 ml-1 grid size-5 flex-none place-items-center rounded transition-colors hover:bg-ink-100"
      ) do
        render Components::Icon.new("x-mark", class: "size-3.5")
      end
    end
  end
end
