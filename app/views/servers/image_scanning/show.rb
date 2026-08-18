# frozen_string_literal: true

class Views::Servers::ImageScanning::Show < Views::Servers::Moderation::SubPluginShow
  private

  def plugin_key
    :image_scanning
  end

  def icon
    "scan"
  end

  def form
    Components::Moderation::ImageScanningForm.new(context: @context)
  end
end
