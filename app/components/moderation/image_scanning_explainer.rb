# frozen_string_literal: true

class Components::Moderation::ImageScanningExplainer < Components::Base
  def view_template
    render Components::Moderation::Explainer.new(
      title: t(".title"),
      rows: [t(".line_memory"), t(".line_staff"), t(".line_fingerprint")],
      ordered: true
    )
  end
end
