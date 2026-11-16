# frozen_string_literal: true

class Components::PrerequisiteSteps < Components::Base
  Step = Data.define(:message, :cta_label, :cta_href)

  def initialize(title:, steps:, icon: "lock")
    @title = title
    @steps = steps
    @icon = icon
  end

  def view_template
    render Components::Callout.new(variant: :info, icon: @icon, class: callout_class) do
      div(class: "flex items-center justify-between gap-4") do
        p(class: "font-semibold text-text-primary") { @title }
        bare_steps.each { |step| cta(step) }
      end
      described_steps.each { |step| step_row(step) }
    end
  end

  private

  def callout_class
    described_steps.empty? ? "mb-5 items-center" : "mb-5"
  end

  def bare_steps
    @steps - described_steps
  end

  def described_steps
    @steps.select(&:message)
  end

  def step_row(step)
    div(class: "mt-3 flex items-center justify-between gap-4") do
      p(class: "text-text-secondary") { step.message }
      cta(step)
    end
  end

  def cta(step)
    render Components::Button.new(
      variant: :secondary,
      href: step.cta_href,
      label: step.cta_label,
      trailing_icon: "arrow-right"
    )
  end
end
