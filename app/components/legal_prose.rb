# frozen_string_literal: true

module Components::LegalProse
  private

  def heading(text)
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { text }
  end

  def paragraph(text)
    p(class: "mb-4 leading-relaxed text-text-secondary") { text }
  end

  def bullets(*items)
    ul(class: "mb-4 list-disc space-y-2 pl-6 text-text-secondary") do
      items.each { |item| li { item } }
    end
  end
end
