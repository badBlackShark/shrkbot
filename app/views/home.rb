# frozen_string_literal: true

class Views::Home < Views::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ImageTag
  include Components::PluginNav

  def view_template
    render Components::PublicShell.new do
      hero
      plugin_showcase
    end
  end

  private

  def hero
    section(class: "mx-auto flex max-w-4xl flex-col items-center gap-12 px-6 py-20 sm:flex-row") do
      div(class: "flex-1") do
        h1(class: "mb-4 font-display text-4xl font-bold leading-tight tracking-tight") do
          span(class: "[font-size:larger]") { render Components::Wordmark.new }
          br
          plain t(".tagline")
          br
          span(class: "text-accent-2-text") { t(".tagline_accent") }
        end
        p(class: "mb-8 max-w-md text-lg leading-relaxed text-text-secondary") { t(".lede") }
        div(class: "flex flex-wrap gap-3") do
          button_to(
            "/auth/discord",
            method: :post,
            data: {turbo: false},
            class: Components::Button.css(variant: :primary, size: :xl)
          ) do
            render Components::Icon.new("sign-in", class: "size-[18px]")
            span { t(".add_to_server") }
          end
          a(
            href: ReleaseInfo::REPO_URL,
            target: "_blank",
            rel: "noopener",
            class: Components::Button.css(variant: :secondary, size: :xl, extra: "text-sm")
          ) do
            render Components::Icon.new("github-logo", class: "size-4")
            plain t(".view_source")
          end
        end
      end
      div(class: "flex-none") do
        image_tag("shrkbot-mascot.png", alt: "", class: "size-48 rounded-xl shadow-lg")
      end
    end
  end

  def plugin_showcase
    section(class: "mx-auto max-w-4xl px-6 pb-20") do
      p(class: "mb-5 text-[11px] font-semibold uppercase tracking-widest text-eyebrow") { t(".plugins_eyebrow") }
      div(class: "plugin-marquee") do
        div(class: "plugin-marquee-track") do
          plugin_cards
          plugin_cards(decorative: true)
        end
      end
      p(class: "mt-6 text-xs text-text-muted") { t(".more_plugins") }
    end
  end

  def plugin_cards(decorative: false)
    div(class: "flex", aria_hidden: decorative ? "true" : nil) do
      %i[roles welcomes logging moderation reminders lfg].each { |key| plugin_card(key) }
    end
  end

  def plugin_card(key)
    render Components::Card.new(class: "mr-4 w-72 flex-none") do
      div(class: "mb-3 flex size-10 items-center justify-center rounded-control bg-accent-soft text-accent-soft-fg") do
        render Components::Icon.new(plugin_icon(key), class: "size-5")
      end
      p(class: "font-display text-sm font-semibold") { t("components.plugin_row.plugin.#{key}.name") }
      p(class: "mt-1 text-sm leading-relaxed text-text-secondary") { t(".plugins.#{key}") }
    end
  end
end
