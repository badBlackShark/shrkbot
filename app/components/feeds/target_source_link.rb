# frozen_string_literal: true

class Components::Feeds::TargetSourceLink < Components::Base
  def initialize(url:, plugin_key:)
    @url = url
    @plugin_key = plugin_key
  end

  def view_template
    return unless @url

    a(href: @url, target: "_blank", rel: "noopener noreferrer", class: Components::Feeds::TargetCard::LINK) do
      plain t(".#{@plugin_key}")
      render Components::Icon.new("arrow-square-out", class: "ml-1 inline size-3.5 align-[-2px]")
    end
  end
end
