# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::UserLabel do
  let(:mention) { "<@123>" }
  let(:username) { "someuser" }
  let(:user) { double("user", mention:, username:) }

  subject(:label) { described_class.for(user) }

  it "combines the mention and the username" do
    expect(label).to eq("<@123> (someuser)")
  end
end
