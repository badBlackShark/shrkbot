# frozen_string_literal: true

class Components::SiteFooter < Components::Base
  def view_template
    footer(class: "border-t border-border-default px-6 py-8 text-center text-xs text-text-muted") do
      plain t(".pre")
      a(href: ReleaseInfo::REPO_URL, class: "underline transition-colors hover:text-text-secondary") { t(".link") }
      plain t(".mid")
      span(class: "text-accent-2-text") { "♥" }
      plain t(".post")
      div(class: "mt-3") do
        render Components::LegalLinks.new
      end
    end
  end
end
