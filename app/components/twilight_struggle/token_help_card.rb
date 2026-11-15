# frozen_string_literal: true

class Components::TwilightStruggle::TokenHelpCard < Components::Base
  GROUPS = {
    game: %w[tournament_name game_id turn winning_method videos],
    usa: %w[usa_player usa_name usa_flag usa_rating_before usa_rating_after usa_rating_change],
    ussr: %w[ussr_player ussr_name ussr_flag ussr_rating_before ussr_rating_after ussr_rating_change],
    winner: %w[winning_player winning_name winning_flag winning_side winning_rating_before winning_rating_after winning_rating_change],
    loser: %w[losing_player losing_name losing_flag losing_side losing_rating_before losing_rating_after losing_rating_change]
  }.freeze

  GROUP_LABEL = "w-20 flex-none text-[11px] font-semibold uppercase tracking-widest text-eyebrow"
  DECIDED_ONLY = %i[winner loser].freeze
  SUMMARY = "group/summary flex cursor-pointer list-none select-none items-center gap-3 py-3 pl-5 pr-3 " \
    "[&::-webkit-details-marker]:hidden"
  CHEVRON = "flex size-8 flex-none items-center justify-center rounded-control text-text-secondary " \
    "transition-colors group-hover/summary:bg-surface-sunken group-hover/summary:text-text-primary"

  def view_template
    render Components::Card.new(padding: :none) do
      details(data: {controller: "disclosure", disclosure_key_value: "twilight-struggle-placeholders"}) do
        summary_row
        render Components::CopyableTokens.new { token_lists }
      end
    end
  end

  private

  def summary_row
    summary(class: SUMMARY, data: {action: "click->disclosure#toggle"}) do
      span(class: "flex-1 text-sm font-semibold") { t("components.placeholder_section.label") }
      span(class: CHEVRON) { render Components::Icon.new("caret-down", class: "dropdown-chevron size-4") }
    end
  end

  def token_lists
    div(class: "flex flex-col gap-2.5 px-5 pb-5") do
      token_list(GROUPS.except(*DECIDED_ONLY))
      p(class: "mt-1 border-t border-border-subtle pt-3 text-xs text-text-secondary") { t(".tie_note") }
      token_list(GROUPS.slice(*DECIDED_ONLY))
    end
  end

  def token_list(groups)
    dl(class: "flex flex-col gap-2.5") do
      groups.each { |group, tokens| token_row(group, tokens) }
    end
  end

  def token_row(group, tokens)
    div(class: "flex flex-col gap-1.5 sm:flex-row sm:items-baseline sm:gap-3") do
      dt(class: GROUP_LABEL) { t(".groups.#{group}") }
      dd(class: "flex flex-wrap gap-1.5") do
        tokens.each do |token|
          render Components::TokenChip.new(token:, description: t(".tokens.#{token}"))
        end
      end
    end
  end
end
