# frozen_string_literal: true

class Views::Admin::BespokePluginGrants::Index < Views::Base
  def initialize(user:, definitions:, grants:, servers:)
    @user = user
    @definitions = definitions
    @grants = grants
    @servers = servers
  end

  def view_template
    render Components::AppShell.new(user: @user) do
      div(class: "mx-auto max-w-2xl px-6 py-10") do
        render Components::PageHeading.new(title: t(".title"), subtitle: t(".subtitle"))
        @definitions.empty? ? empty : cards
      end
    end
  end

  private

  def empty
    render Components::EmptyState.new(title: t(".empty_title"), body: t(".empty_body")) { nil }
  end

  def cards
    div(class: "flex flex-col gap-4") do
      @definitions.each { |definition| card(definition) }
    end
  end

  def card(definition)
    render Components::Admin::BespokePluginCard.new(
      definition:,
      grants: @grants.fetch(definition.key, []),
      servers: @servers
    )
  end
end
