# frozen_string_literal: true

class Views::Servers::Moderation::SubPluginShow < Views::Servers::SubPluginShow
  def initialize(server_configuration:, user:, context:)
    super(server_configuration:, user:)
    @context = context
  end

  private

  def toggle_locked?
    super || !@context.staff_role_present?
  end

  def toggle_reason
    super || (t(".role_locked_reason") unless @context.staff_role_present?)
  end

  def subline_note
    t("views.servers.moderation.sub_plugin_show.shared_settings_note")
  end

  def body
    group_subline
    no_role_callout
    render form
  end

  def no_role_callout
    return unless group_enabled? && !@context.staff_role_present?

    render Components::Callout.new(variant: :warning) do
      span do
        b(class: "text-warning") { t(".no_role_callout_lead") }
        plain " "
        plain t(".no_role_callout_body")
        plain " "
        a(href: parent_path, class: "underline") { t(".no_role_callout_link") }
        plain t(".no_role_callout_suffix")
      end
    end
  end
end
