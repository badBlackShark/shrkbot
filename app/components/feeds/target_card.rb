# frozen_string_literal: true

class Components::Feeds::TargetCard < Components::Base
  LINK = "mt-2 inline-block text-sm text-accent-soft-fg underline"

  def initialize(target:, source:)
    @target = target
    @source = source
  end

  def view_template
    render Components::Card.new(class: "flex flex-wrap items-center gap-4") do
      render Components::Feeds::WatchImage.new(url: @target.image_url, source: @source, loading: "eager")
      div(class: "min-w-0 flex-1") do
        h1(class: "font-display text-2xl font-bold tracking-tight") { @target.name }
        caption
        yield
      end
    end
  end

  private

  def caption
    key = "components.feeds.target_card.#{@source.key}.external_id"
    return unless I18n.exists?(key)

    p(class: "mt-0.5 text-sm text-text-secondary") { t(key, id: @target.external_id) }
  end
end
