# frozen_string_literal: true

class Views::PrivacyPolicy < Views::Base
  include Components::LegalProse

  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::LegalPage.new(title: t(".title"), updated: t(".updated"), user: @user) do
      intro_section
      audience_section
      data_section
      messages_section
      not_section
      basis_section
      sharing_section
      retention_section
      deletion_section
      rights_section
      security_section
      cookies_section
      children_section
      changes_section
    end
  end

  private

  def intro_section
    paragraph(t(".intro_1"))
    paragraph(t(".intro_2"))
  end

  def audience_section
    heading(t(".audience_h"))
    bullets(t(".audience_members"), t(".audience_dashboard"))
  end

  def data_section
    heading(t(".data_h"))
    paragraph(t(".data_lead"))
    bullets(
      t(".data_guild"),
      t(".data_account"),
      t(".data_reminders"),
      t(".data_notifications"),
      t(".data_operational")
    )
  end

  def messages_section
    heading(t(".messages_h"))
    paragraph(t(".messages_p_1"))
    paragraph(t(".messages_p_2"))
    paragraph(t(".messages_p_3"))
    paragraph(t(".messages_p_4"))
  end

  def not_section
    heading(t(".not_h"))
    paragraph(t(".not_p"))
  end

  def basis_section
    heading(t(".basis_h"))
    paragraph(t(".basis_p"))
  end

  def sharing_section
    heading(t(".sharing_h"))
    paragraph(t(".sharing_p"))
  end

  def retention_section
    heading(t(".retention_h"))
    bullets(
      t(".retention_guild"),
      t(".retention_reminders"),
      t(".retention_account"),
      t(".retention_infra")
    )
  end

  def deletion_section
    heading(t(".deletion_h"))
    paragraph(t(".deletion_lead"))
    bullets(
      t(".deletion_guild"),
      t(".deletion_reminders"),
      t(".deletion_account"),
      t(".deletion_contact")
    )
  end

  def rights_section
    heading(t(".rights_h"))
    paragraph(t(".rights_p"))
  end

  def security_section
    heading(t(".security_h"))
    paragraph(t(".security_p"))
  end

  def cookies_section
    heading(t(".cookies_h"))
    paragraph(t(".cookies_p"))
  end

  def children_section
    heading(t(".children_h"))
    paragraph(t(".children_p"))
  end

  def changes_section
    heading(t(".changes_h"))
    paragraph(t(".changes_p"))
  end
end
