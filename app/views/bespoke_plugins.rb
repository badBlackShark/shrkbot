# frozen_string_literal: true

class Views::BespokePlugins < Views::Base
  include Components::PluginNav

  STEPS = %i[ask fit ship].freeze

  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::PublicShell.new(user: @user) do
      hero
      steps
      example
      cost
    end
  end

  private

  def hero
    section(class: "mx-auto max-w-3xl px-6 pb-14 pt-20") do
      eyebrow(t(".eyebrow"))
      h1(class: "mb-5 font-display text-4xl font-bold leading-tight tracking-tight") { t(".headline") }
      p(class: "mb-8 text-lg leading-relaxed text-text-secondary") { t(".lede") }
      contact_actions
    end
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

  def steps
    section(class: "mx-auto max-w-3xl px-6 pb-14") do
      eyebrow(t(".steps_eyebrow"))
      div(class: "flex flex-col gap-4 sm:flex-row") do
        STEPS.each_with_index { |key, index| step_card(key, index) }
      end
    end
  end

  def step_card(key, index)
    render Components::Card.new(class: "flex-1") do
      p(class: "mb-3 font-mono text-xs text-accent-2-text") { (index + 1).to_s.rjust(2, "0") }
      p(class: "font-display text-sm font-semibold") { t(".steps.#{key}.title") }
      p(class: "mt-1 text-sm leading-relaxed text-text-secondary") { t(".steps.#{key}.body") }
    end
  end

  def example
    section(class: "mx-auto max-w-3xl px-6 pb-14") do
      eyebrow(t(".example_eyebrow"))
      render Components::Card.new(padding: :lg) do
        div(class: "flex items-start gap-4") do
          render Components::PluginTile.new(icon: plugin_icon(:twilight_struggle))
          div do
            p(class: "font-display text-sm font-semibold") { t("components.plugin_row.plugin.twilight_struggle.name") }
            p(class: "mt-1 text-sm leading-relaxed text-text-secondary") { t(".example_body") }
          end
        end
      end
    end
  end

  def cost
    section(class: "mx-auto max-w-3xl px-6 pb-24") do
      eyebrow(t(".cost_eyebrow"))
      render Components::Callout.new(variant: :neutral) do
        p(class: "leading-relaxed text-text-secondary") { t(".cost_body") }
      end
    end
  end

  def eyebrow(text)
    p(class: "mb-5 text-[11px] font-semibold uppercase tracking-widest text-eyebrow") { text }
  end
end
