# frozen_string_literal: true

class Views::PrivacyPolicy < Views::Base
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
    controller_section
    data_section
    purpose_section
    sharing_section
    retention_section
    rights_section
    cookies_section
    changes_section
  end

  def intro_section
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".intro") }
  end

  def controller_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".controller_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".controller_p") }
  end

  def data_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".data_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".data_lead") }
    ul(class: "mb-4 list-disc space-y-2 pl-6 text-text-secondary") do
      li { t(".data_account") }
      li { t(".data_guild") }
      li { t(".data_reminders") }
      li { t(".data_overwrites") }
      li { t(".data_session") }
    end
  end

  def purpose_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".purpose_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".purpose_p") }
  end

  def sharing_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".sharing_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".sharing_p") }
  end

  def retention_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".retention_h") }
    ul(class: "mb-4 list-disc space-y-2 pl-6 text-text-secondary") do
      li { t(".retention_delivery") }
      li { t(".retention_guild") }
      li { t(".retention_account") }
      li { t(".retention_infra") }
    end
  end

  def rights_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".rights_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".rights_p") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".rights_delete") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".rights_contact") }
  end

  def cookies_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".cookies_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".cookies_p") }
  end

  def changes_section
    h2(class: "mb-3 mt-10 font-display text-xl font-semibold") { t(".changes_h") }
    p(class: "mb-4 leading-relaxed text-text-secondary") { t(".changes_p") }
  end
end
