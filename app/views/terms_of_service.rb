# frozen_string_literal: true

class Views::TermsOfService < Views::Base
  def view_template
    render Components::PublicShell.new do
      article(class: "mx-auto max-w-2xl px-6 py-16") do
        h1(class: "mb-2 font-display text-3xl font-bold tracking-tight") { t(".title") }
        p(class: "mb-10 text-sm text-text-muted") { t(".updated") }
        sections
      end
    end
  end

  private

  def sections
    intro_section
    service_section
    use_section
    availability_section
    termination_section
    liability_section
    law_section
    contact_section
  end

  def intro_section
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".intro") }
  end

  def service_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".service_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".service_p") }
  end

  def use_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".use_h") }
    ul(class: "mb-4 list-disc space-y-2 pl-6 text-text-secondary") do
      li { t(".use_items_1") }
      li { t(".use_items_2") }
      li { t(".use_items_3") }
    end
  end

  def availability_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".availability_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".availability_p") }
  end

  def termination_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".termination_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".termination_p") }
  end

  def liability_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".liability_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".liability_p") }
  end

  def law_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".law_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".law_p") }
  end

  def contact_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".contact_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".contact_p") }
  end
end
