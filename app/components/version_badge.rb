# frozen_string_literal: true

class Components::VersionBadge < Components::Base
  def view_template
    release = ReleaseInfo.current
    return unless release

    render Components::Tooltip.new(text: t(".released", date: release.released_on.strftime("%d. %b, %Y")), placement: :down) do
      a(
        href: release.release_url,
        target: "_blank",
        rel: "noopener",
        aria_label: t(".label", version: release.number),
        class: "transition-opacity hover:opacity-80"
      ) do
        render Components::Badge.new(variant: :neutral) { "v#{release.number}" }
      end
    end
  end
end
