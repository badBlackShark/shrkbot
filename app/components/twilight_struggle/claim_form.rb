# frozen_string_literal: true

class Components::TwilightStruggle::ClaimForm < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(tournament:, servers:)
    @tournament = tournament
    @servers = servers
  end

  def view_template
    return no_servers_note if @servers.empty?

    form_with(url: twilight_struggle_tournament_claim_path(@tournament), method: :post, class: "flex flex-none items-center gap-2") do
      render Components::TomSelect.new(
        name: "server_configuration_id",
        options: server_options,
        include_blank: true,
        controller_data: {tom_select_placeholder_value: t(".placeholder")}
      )
      render Components::Button.new(label: t(".claim"), size: :sm, type: "submit")
    end
  end

  private

  def no_servers_note
    p(class: "flex-none text-sm text-text-muted") { t(".no_servers") }
  end

  def server_options
    ServerOptions.new(@servers).options
  end
end
