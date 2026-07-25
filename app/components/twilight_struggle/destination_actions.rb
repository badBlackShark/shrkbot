# frozen_string_literal: true

class Components::TwilightStruggle::DestinationActions < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(tournament:)
    @tournament = tournament
  end

  def view_template
    div(class: "flex flex-none items-center gap-2") do
      server_name
      configure_link
      release_form
    end
  end

  private

  def server_name
    span(class: "text-sm text-text-secondary") { @tournament.server_configuration.name }
  end

  def configure_link
    render Components::Button.new(
      variant: :secondary,
      size: :sm,
      label: t(".configure"),
      href: edit_twilight_struggle_tournament_path(@tournament)
    )
  end

  def release_form
    form_with(url: twilight_struggle_tournament_claim_path(@tournament), method: :delete) do
      render Components::Button.new(
        variant: :ghost,
        size: :sm,
        type: "submit",
        label: t(".release"),
        data: {turbo_confirm: t(".release_confirm")}
      )
    end
  end
end
