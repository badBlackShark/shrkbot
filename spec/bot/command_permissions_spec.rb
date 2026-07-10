# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommandPermissions do
  def event_for(user_id:)
    user = double("user", id: user_id)
    double("event", user:)
  end

  describe ".permitted?" do
    subject(:permitted) { described_class.permitted?(event:, owner_only:) }

    context "when the user is the configured owner" do
      before do
        allow(BotConfig).to receive(:owner_id).and_return("42")
      end

      let(:event) { event_for(user_id: 42) }

      context "requesting owner_only" do
        let(:owner_only) { true }

        it "grants access" do
          is_expected.to be(true)
        end
      end

      context "plain command" do
        let(:owner_only) { false }

        it "grants access" do
          is_expected.to be(true)
        end
      end
    end

    context "when the user is not the configured owner and owner_only is true" do
      before do
        allow(BotConfig).to receive(:owner_id).and_return("42")
      end

      let(:event) { event_for(user_id: 7) }
      let(:owner_only) { true }

      it "denies access" do
        is_expected.to be(false)
      end
    end

    context "when no owner is configured and command is not owner_only" do
      before do
        allow(BotConfig).to receive(:owner_id).and_return(nil)
      end

      let(:event) { event_for(user_id: 7) }
      let(:owner_only) { false }

      it "grants access" do
        is_expected.to be(true)
      end
    end
  end
end
