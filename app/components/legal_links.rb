# frozen_string_literal: true

class Components::LegalLinks < Components::Base
  def view_template
    nav(class: "flex items-center justify-center gap-4 text-xs text-text-muted") do
      a(href: privacy_policy_path, class: link_classes) { t(".privacy") }
      a(href: terms_of_service_path, class: link_classes) { t(".terms") }
    end
  end

  private

  def link_classes
    "underline transition-colors hover:text-text-secondary"
  end
end
