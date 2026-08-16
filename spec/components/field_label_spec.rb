# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::FieldLabel do
  subject(:html) { described_class.new.call { "Channel" } }

  it "renders the block content inside a label carrying the shared classes" do
    expect(html).to include("<label").and include('class="mb-1.5 block text-sm font-semibold"').and include("Channel")
  end
end
