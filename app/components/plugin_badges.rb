# frozen_string_literal: true

class Components::PluginBadges < Components::Base
  def initialize(key:)
    @key = key
  end

  def view_template
    new_badge if PluginCatalog.recently_added?(@key)
    beta_badge if PluginCatalog.beta?(@key)
  end

  private

  def new_badge
    render Components::Badge.new(variant: :brand) do
      render Components::Icon.new("sparkle", weight: :fill, class: "size-3.5")
      plain t(".new")
    end
  end

  def beta_badge
    render Components::Tooltip.new(text: beta_hint) do
      render Components::Badge.new(variant: :beta, tabindex: 0) do
        render Components::Icon.new("flask", class: "size-3.5")
        plain t(".beta")
      end
    end
  end

  def beta_hint
    owner = Bot::Discord::OwnerUsername.call
    owner ? t(".beta_hint", owner:) : t(".beta_hint_unknown")
  end
end
