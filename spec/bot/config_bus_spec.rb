# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConfigBus do
  let(:redis) { double("redis") }

  before do
    allow(Redis).to receive(:new).and_return(redis)
    allow(redis).to receive(:publish)
  end

  describe ".repost_roles" do
    let(:set) { create(:role_set) }

    it "publishes a roles_repost event carrying the set id" do
      described_class.repost_roles(set)

      expect(redis).to have_received(:publish).with(
        described_class::CHANNEL,
        JSON.generate(type: "roles_repost", set_id: set.id)
      )
    end
  end
end
