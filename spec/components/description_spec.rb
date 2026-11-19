# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Description do
  subject(:html) { described_class.new.call { "Posts every result." } }

  it "renders the line under a title as a small secondary paragraph" do
    expect(html).to eq('<p class="mt-0.5 text-sm text-text-secondary">Posts every result.</p>')
  end
end
