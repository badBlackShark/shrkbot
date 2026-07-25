# frozen_string_literal: true

class Components::TwilightStruggle::TokenHelpCard < Components::Base
  TOKENS = %w[
    tournament_name game_id turn winning_method
    winning_player losing_player winning_side losing_side
    usa_player ussr_player usa_name ussr_name winning_name losing_name
    usa_flag ussr_flag winning_flag losing_flag videos
  ].freeze

  def view_template
    render Components::Card.new do
      p(class: "text-sm font-semibold") { t(".label") }
      p(class: "mb-3 mt-0.5 text-sm text-text-secondary") { t(".help") }
      div(class: "flex flex-wrap gap-1.5") do
        TOKENS.each { |token| chip(token) }
      end
    end
  end

  private

  def chip(token)
    render Components::Tooltip.new(text: t(".tokens.#{token}")) do
      code(
        tabindex: "0",
        class: "cursor-help rounded bg-surface-sunken px-1.5 py-0.5 font-mono text-xs text-accent-soft-fg " \
          "focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)]"
      ) { "{#{token}}" }
    end
  end
end
