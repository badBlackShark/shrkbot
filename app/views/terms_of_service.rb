# frozen_string_literal: true

class Views::TermsOfService < Views::Base
  include Components::LegalProse

  def view_template
    render Components::LegalPage.new(title: t(".title"), updated: t(".updated")) do
      intro_section
      service_section
      eligibility_section
      use_section
      admin_section
      availability_section
      liability_section
      privacy_section
      source_section
      termination_section
      changes_section
      law_section
    end
  end

  private

  def intro_section
    paragraph(t(".intro"))
  end

  def service_section
    heading(t(".service_h"))
    paragraph(t(".service_p"))
  end

  def eligibility_section
    heading(t(".eligibility_h"))
    paragraph(t(".eligibility_p"))
  end

  def use_section
    heading(t(".use_h"))
    paragraph(t(".use_lead"))
    bullets(
      t(".use_items_1"),
      t(".use_items_2"),
      t(".use_items_3"),
      t(".use_items_4")
    )
  end

  def admin_section
    heading(t(".admin_h"))
    paragraph(t(".admin_p"))
  end

  def availability_section
    heading(t(".availability_h"))
    paragraph(t(".availability_p"))
  end

  def liability_section
    heading(t(".liability_h"))
    paragraph(t(".liability_p"))
  end

  def privacy_section
    heading(t(".privacy_h"))
    p(class: "mb-4 leading-relaxed text-text-secondary") do
      plain t(".privacy_pre")
      a(href: privacy_policy_path, class: "underline transition-colors hover:text-text-primary") { t(".privacy_link") }
      plain t(".privacy_post")
    end
  end

  def source_section
    heading(t(".source_h"))
    paragraph(t(".source_p"))
  end

  def termination_section
    heading(t(".termination_h"))
    paragraph(t(".termination_p"))
  end

  def changes_section
    heading(t(".changes_h"))
    paragraph(t(".changes_p"))
  end

  def law_section
    heading(t(".law_h"))
    paragraph(t(".law_p"))
  end
end
