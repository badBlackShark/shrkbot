# frozen_string_literal: true

class Components::Feeds::TargetCard < Components::Base
  def initialize(target:, plugin_key:, change_href:)
    @target = target
    @plugin_key = plugin_key
    @change_href = change_href
  end

  def view_template
    render Components::Card.new(class: "flex flex-wrap items-center gap-4") do
      render Components::Feeds::WatchImage.new(url: @target.image_url)
      div(class: "min-w-0 flex-1") do
        h1(class: "font-display text-2xl font-bold tracking-tight") { @target.name }
        p(class: "mt-0.5 text-sm text-text-secondary") { t(".#{@plugin_key}.external_id", id: @target.external_id) }
        change_link
      end
    end
  end

  private

  def change_link
    a(href: @change_href, class: "mt-2 inline-block text-sm text-accent-soft-fg underline") { t(".change") }
  end
end
