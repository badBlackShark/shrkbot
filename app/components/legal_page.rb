# frozen_string_literal: true

class Components::LegalPage < Components::Base
  CONTACT_EMAIL = "info@shrkbot.com"
  SUPPORT_URL = "https://discord.gg/3gwFMTY"

  def initialize(title:, updated:)
    @title = title
    @updated = updated
  end

  def view_template(&block)
    render Components::PublicShell.new do
      article(class: "mx-auto max-w-2xl px-6 py-16") do
        h1(class: "mb-2 font-display text-3xl font-bold tracking-tight") { @title }
        p(class: "mb-10 text-sm text-text-muted") { @updated }
        yield
        contact_section
      end
    end
  end

  private

  def contact_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".contact_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") do
      plain "#{t(".contact_operator")} — "
      a(href: "mailto:#{CONTACT_EMAIL}", class: link_classes) { CONTACT_EMAIL }
      plain " / "
      a(href: SUPPORT_URL, class: link_classes) { t(".contact_support") }
    end
  end

  def link_classes
    "underline transition-colors hover:text-text-primary"
  end
end
