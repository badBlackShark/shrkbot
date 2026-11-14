# frozen_string_literal: true

class Components::PrereqGate < Components::Base
  Step = Data.define(:message, :cta_label, :cta_href)

  def initialize(title:, steps:, icon: "lock")
    @title = title
    @steps = steps
    @icon = icon
  end

  def view_template(&block)
    div(class: "relative") do
      overlay
      div(
        inert: true,
        class: "flex flex-col gap-5 opacity-45"
      ) { yield }
    end
  end

  private

  def overlay
    div(class: "anim-fade absolute inset-0 z-20 flex items-center justify-center rounded-card bg-surface-page/70 backdrop-blur-[1px]") do
      div(class: "max-w-xs rounded-card border border-border-default bg-surface-card px-6 py-5 text-center shadow-md") do
        render Components::Icon.new(@icon, class: "mx-auto block size-5 text-text-muted")
        p(class: "mt-2 text-sm font-semibold text-text-primary") { @title }
        @steps.each_with_index { |step, index| step_block(step, index) }
      end
    end
  end

  def step_block(step, index)
    div(class: index.zero? ? "mt-1" : "mt-4") do
      p(class: "mb-4 text-xs text-text-secondary") { step.message }
      render Components::Button.new(
        variant: :secondary,
        href: step.cta_href,
        label: step.cta_label,
        trailing_icon: "arrow-right"
      )
    end
  end
end
