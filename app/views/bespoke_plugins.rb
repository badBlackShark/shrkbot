# frozen_string_literal: true

class Views::BespokePlugins < Views::Base
  include Components::PluginNav

  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::PublicShell.new(user: @user) do
      div(class: "mx-auto max-w-3xl px-6 pb-16 pt-18") do
        div(class: "flex max-w-160 flex-col gap-10") do
          intro
          example
          cost
          contact_actions
        end
      end
    end
  end

  private

  def intro
    div(class: "flex flex-col gap-5") do
      h1(class: "font-display text-4xl font-bold leading-tight tracking-tight") { t(".title") }
      p(class: "text-lg leading-relaxed") { t(".lede") }
      p(class: "leading-relaxed text-text-secondary") { t(".idea") }
    end
  end

  def example
    section(class: "flex flex-col gap-3") do
      heading(t(".example_heading"))
      render Components::Card.new(class: "flex items-center gap-4") do
        render Components::PluginTile.new(icon: plugin_icon(:twilight_struggle))
        div(class: "min-w-0 flex-1") do
          div(class: "flex flex-wrap items-center gap-2") do
            span(class: "font-display font-semibold") { t("components.plugin_row.plugin.twilight_struggle.name") }
            render Components::BespokeBadge.new
          end
          p(class: "mt-0.5 text-sm leading-[1.5] text-pretty text-text-secondary") do
            example_body
          end
        end
      end
    end
  end

  def example_body
    plain t(".example_body_pre")
    a(
      href: t(".example_url"),
      target: "_blank",
      rel: "noopener",
      class: "underline transition-colors hover:text-text-primary"
    ) { t(".example_body_link") }
    plain t(".example_body_post")
  end

  def cost
    section(class: "flex flex-col gap-3") do
      heading(t(".cost_heading"))
      p(class: "leading-relaxed text-text-secondary") { t(".cost_body") }
    end
  end

  def heading(text)
    h2(class: "font-display text-lg font-semibold") { text }
  end

  def contact_actions
    div(class: "flex flex-wrap gap-3") do
      render Components::Button.new(
        href: "mailto:#{SupportContact::EMAIL}",
        label: t(".write"),
        icon: "envelope-simple",
        size: :xl
      )
      render Components::Button.new(
        href: SupportContact::SERVER_URL,
        label: t(".ask_in_server"),
        icon: "discord-logo",
        variant: :secondary,
        size: :xl,
        target: "_blank",
        rel: "noopener"
      )
    end
  end
end
