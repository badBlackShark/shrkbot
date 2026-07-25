# frozen_string_literal: true

class Views::TwilightStruggle::Tournaments::Edit < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(user:, tournament:)
    @user = user
    @tournament = tournament
  end

  def view_template
    render Components::AppShell.new(user: @user) do
      div(class: "mx-auto max-w-3xl px-6 pb-28 pt-8") do
        render Components::Breadcrumb.new(crumbs)
        form_with(url: twilight_struggle_tournament_path(@tournament), method: :patch, data: form_data) do
          render Components::PageHeading.new(title: @tournament.name, subtitle: t(".subtitle", server: @tournament.server_configuration.name))
          render Components::TwilightStruggle::ConfigForm.new(tournament: @tournament)
          render Components::SaveBar.new
        end
      end
    end
  end

  private

  def crumbs
    [
      {label: t(".tournaments"), href: twilight_struggle_tournaments_path},
      {label: @tournament.name}
    ]
  end

  def form_data
    {
      controller: "save-bar",
      action: "input->save-bar#check change->save-bar#check turbo:submit-end->save-bar#saved"
    }
  end
end
