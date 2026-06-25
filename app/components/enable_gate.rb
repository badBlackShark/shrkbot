# frozen_string_literal: true

class Components::EnableGate < Components::Base
  def initialize(enabled:, title:, message:, enable_label:)
    @enabled = enabled
    @title = title
    @message = message
    @enable_label = enable_label
  end

  def view_template(&block)
    div(class: "relative") do
      overlay
      div(
        data: {enable_gate_target: "content"},
        inert: (true unless @enabled),
        class: "flex flex-col gap-5 transition-opacity #{"opacity-45" unless @enabled}"
      ) { yield }
    end
  end

  private

  def overlay
    div(
      data: {enable_gate_target: "overlay"},
      class: "anim-fade absolute inset-0 z-20 flex items-center justify-center rounded-card bg-surface-page/70 backdrop-blur-[1px] #{"hidden" if @enabled}"
    ) do
      div(class: "max-w-xs rounded-card border border-border-default bg-surface-card px-6 py-5 text-center shadow-md") do
        render Components::Icon.new("lock", class: "mx-auto block size-5 text-text-muted")
        p(class: "mt-2 text-sm font-semibold text-text-primary") { @title }
        p(class: "mb-4 mt-1 text-xs text-text-secondary") { @message }
        render Components::Button.new(variant: :primary, label: @enable_label, data: {action: "enable-gate#enable"})
      end
    end
  end
end
