# frozen_string_literal: true

class Views::Home < Views::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ImageTag
  include Components::PluginNav

  REPO_URL = "https://github.com/badBlackShark/shrkbot"

  def view_template
    div(class: "flex min-h-screen flex-col") do
      header_bar
      main(class: "flex-1") do
        hero
        plugin_showcase
      end
      footer_bar
    end
  end

  private

  def header_bar
    header(class: "app-bar z-30 flex h-16 items-center gap-3 px-6") do
      image_tag("shrkbot-mascot.png", alt: "shrkbot", class: "size-9 rounded-control")
      span(class: "font-display text-lg font-bold tracking-tight") do
        render Components::Wordmark.new
      end
      div(class: "flex-1")
      render Components::ThemeToggle.new
      button_to(
        "/auth/discord",
        method: :post,
        data: {turbo: false},
        class: Components::Button.css(variant: :primary, size: :lg)
      ) do
        render Components::Icon.new("sign-in", class: "size-4")
        span { t(".sign_in") }
      end
    end
  end

  def hero
    section(class: "mx-auto flex max-w-4xl flex-col items-center gap-12 px-6 py-20 sm:flex-row") do
      div(class: "flex-1") do
        p(class: "mb-3 text-[11px] font-semibold uppercase tracking-widest text-eyebrow") { t(".eyebrow") }
        h1(class: "mb-4 font-display text-4xl font-bold leading-tight tracking-tight") do
          plain t(".headline")
          br
          plain t(".headline_end")
          span(class: "text-text-muted") { " #{t(".headline_muted")}" }
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
            href: REPO_URL,
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
      %i[roles welcomes logging reminders].each { |key| plugin_card(key) }
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

  def footer_bar
    footer(class: "border-t border-border-default px-6 py-8 text-center text-xs text-text-muted") do
      plain t(".footer_pre")
      a(href: REPO_URL, class: "underline transition-colors hover:text-text-secondary") { t(".footer_link") }
      plain t(".footer_mid")
      span(class: "text-accent-2-text") { "♥" }
      plain t(".footer_post")
    end
  end
end
