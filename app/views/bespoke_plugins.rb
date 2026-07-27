# frozen_string_literal: true

class Views::BespokePlugins < Views::Base
  include Components::LegalProse

  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::LegalPage.new(title: t(".title"), user: @user) do
      intro_section
      example_section
      process_section
      cost_section
    end
  end

  private

  def intro_section
    paragraph(t(".intro_1"))
    paragraph(t(".intro_2"))
  end

  def example_section
    heading(t(".example_h"))
    paragraph(t(".example_p"))
  end

  def process_section
    heading(t(".process_h"))
    bullets(t(".process_ask"), t(".process_scope"), t(".process_ship"))
  end

  def cost_section
    heading(t(".cost_h"))
    paragraph(t(".cost_p"))
  end
end
