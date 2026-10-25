# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PlaceholderChips do
  subject(:html) { described_class.new(tokens: {"game" => "The game's name.", "title" => "The post's title."}).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }

  it "renders one copy chip per token" do
    expect(html).to include(%(data-clipboard-text-param="{game}"), %(data-clipboard-text-param="{title}"))
  end

  it "describes each token in its tooltip" do
    expect(html).to include("The game&#39;s name.", "The post&#39;s title.")
  end
end
