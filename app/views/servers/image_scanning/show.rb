# frozen_string_literal: true

class Views::Servers::ImageScanning::Show < Views::Servers::Moderation::SubPluginShow
  private

  def active_key
    :image_scanning
  end

  def icon
    "scan"
  end

  def url
    server_image_scanning_path(@config.discord_id)
  end

  def enable_field
    "image_scanning[enabled]"
  end

  def form
    Components::Moderation::ImageScanningForm.new(context: @context)
  end
end
