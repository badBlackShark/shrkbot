# frozen_string_literal: true

class Components::PrerequisiteSteps < Components::Base
  Step = Data.define(:message, :cta_label, :cta_href)

  def initialize(title:, steps:, icon: "lock")
    @title = title
    @steps = steps
    @icon = icon
  end

  def view_template
    render Components::Callout.new(variant: :info, icon: @icon, class: "mb-5") do
      p(class: "font-semibold text-text-primary") { @title }
      @steps.each { |step| step_row(step) }
    end
  end

  private

  def step_row(step)
    div(class: "mt-3 flex items-center justify-between gap-4") do
      p(class: "text-text-secondary") { step.message }
      render Components::Button.new(
        variant: :secondary,
        href: step.cta_href,
        label: step.cta_label,
        trailing_icon: "arrow-right"
      )
    end
  end
end
