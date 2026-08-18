# frozen_string_literal: true

class Views::Servers::SpamProtection::Show < Views::Servers::Moderation::SubPluginShow
  private

  def plugin_key
    :spam_protection
  end

  def icon
    "megaphone-slash"
  end

  def form
    Components::Moderation::SpamProtectionForm.new(context: @context)
  end
end
