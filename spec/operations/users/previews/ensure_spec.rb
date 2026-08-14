# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Users::Previews::Ensure do
  subject(:result) { described_class.call }

  it "creates the demo user at the preview data's negative discord_id" do
    expect { result }.to change {
      User.where(discord_id: PreviewData.user[:discord_id]).count
    }.from(0).to(1)
  end

  it "sets the username and display name from the preview data" do
    user = result.value

    expect(user.username).to eq(PreviewData.user[:username])
    expect(user.display_name).to eq(PreviewData.user[:display_name])
  end

  describe "calling it twice" do
    it "does not create a second user" do
      described_class.call

      expect { described_class.call }.not_to change(User, :count)
    end

    it "returns the same user" do
      first = described_class.call.value

      expect(described_class.call.value).to eq(first)
    end
  end
end
