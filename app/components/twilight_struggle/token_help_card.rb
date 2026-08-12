# frozen_string_literal: true

class Components::TwilightStruggle::TokenHelpCard < Components::Base
  GROUPS = {
    game: %w[tournament_name game_id turn winning_method videos],
    usa: %w[usa_player usa_name usa_flag usa_rating_before usa_rating_after usa_rating_change],
    ussr: %w[ussr_player ussr_name ussr_flag ussr_rating_before ussr_rating_after ussr_rating_change],
    winner: %w[winning_player winning_name winning_flag winning_side winning_rating_before winning_rating_after winning_rating_change],
    loser: %w[losing_player losing_name losing_flag losing_side losing_rating_before losing_rating_after losing_rating_change]
  }.freeze

  CHIP = "cursor-pointer rounded bg-surface-sunken px-1.5 py-0.5 font-mono text-xs text-accent-soft-fg " \
    "transition-colors hover:bg-accent-soft focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)]"

  GROUP_LABEL = "w-20 flex-none text-[11px] font-semibold uppercase tracking-widest text-eyebrow"

  def view_template
    render Components::Card.new do
      p(class: "text-sm font-semibold") { t(".label") }
      p(class: "mb-3 mt-0.5 text-sm text-text-secondary") { t(".help") }
      div(
        data: {
          controller: "clipboard",
          clipboard_copied_label_value: t(".copied"),
          clipboard_failed_label_value: t(".copy_failed")
        }
      ) do
        dl(class: "flex flex-col gap-2.5") do
          GROUPS.each { |group, tokens| token_row(group, tokens) }
        end
        announcer
      end
    end
  end

  private

  def announcer
    span(class: "sr-only", role: "status", data: {clipboard_target: "announcer"})
  end

  def token_row(group, tokens)
    div(class: "flex flex-col gap-1.5 sm:flex-row sm:items-baseline sm:gap-3") do
      dt(class: GROUP_LABEL) { t(".groups.#{group}") }
      dd(class: "flex flex-wrap gap-1.5") do
        tokens.each { |token| chip(token) }
      end
    end
  end

  def chip(token)
    render Components::Tooltip.new(text: t(".tokens.#{token}")) do
      button(
        type: "button",
        class: CHIP,
        data: {action: "clipboard#copy", clipboard_text_param: "{#{token}}"}
      ) { "{#{token}}" }
    end
  end
end
