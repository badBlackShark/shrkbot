# frozen_string_literal: true

class Views::Imprint < Views::Base
  include Components::LegalProse

  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::LegalPage.new(title: t(".title"), user: @user, contact: false) do
      paragraph(t(".legal_ref"))
      provider_section
      contact_section
    end
  end

  private

  def provider_section
    heading(t(".provider_h"))
    p(class: "mb-4 leading-relaxed text-text-secondary") do
      plain t(".provider_name")
      br
      plain t(".provider_street")
      br
      plain t(".provider_city")
      br
      plain t(".provider_country")
    end
  end

  def contact_section
    heading(t(".contact_h"))
    p(class: "mb-4 leading-relaxed text-text-secondary") do
      plain t(".contact_email_pre")
      a(href: "mailto:#{Components::LegalPage::CONTACT_EMAIL}", class: link_classes) { Components::LegalPage::CONTACT_EMAIL }
    end
    p(class: "leading-relaxed text-text-secondary") { t(".contact_phone") }
    p(class: "mb-4 text-sm text-text-muted") { t(".contact_phone_note") }
  end
end
