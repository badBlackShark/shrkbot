# frozen_string_literal: true

class Views::TwilightStruggle::Tournaments::Index < Views::Base
  def initialize(user:, tournaments:, servers:, archived:)
    @user = user
    @tournaments = tournaments
    @servers = servers
    @archived = archived
  end

  def view_template
    render Components::AppShell.new(user: @user) do
      div(class: "mx-auto max-w-3xl px-6 py-10") do
        render Components::PageHeading.new(title: t(".title"), subtitle: t(".subtitle"))
        render Components::TwilightStruggle::ArchiveFilter.new(archived: @archived)
        @tournaments.empty? ? empty : list
      end
    end
  end

  private

  def empty
    render Components::EmptyState.new(title: t(".empty_title"), body: empty_body) { nil }
  end

  def empty_body
    @archived ? t(".empty_archived") : t(".empty_body")
  end

  def list
    div(class: "mt-5 flex flex-col gap-3") do
      @tournaments.each { |tournament| render Components::TwilightStruggle::TournamentRow.new(tournament:, servers: @servers) }
    end
  end
end
