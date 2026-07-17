# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::CommandPermissions do
  def event_for(user_id:)
    user = double("user", id: user_id)
    double("event", user:)
  end

  describe ".permitted?" do
    subject(:permitted) { described_class.permitted?(event:, owner_only:) }

    context "when the user is the configured owner" do
      before do
        allow(Bot::Config).to receive(:owner_id).and_return("42")
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
        allow(Bot::Config).to receive(:owner_id).and_return("42")
      end

      let(:event) { event_for(user_id: 7) }
      let(:owner_only) { true }

      it "denies access" do
        is_expected.to be(false)
      end
    end

    context "when no owner is configured and command is not owner_only" do
      before do
        allow(Bot::Config).to receive(:owner_id).and_return(nil)
      end

      let(:event) { event_for(user_id: 7) }
      let(:owner_only) { false }

      it "grants access" do
        is_expected.to be(true)
      end
    end

    context "when the command declares required permissions" do
      subject(:permitted) do
        described_class.permitted?(event:, owner_only: false, required_permissions: [:manage_messages])
      end

      let(:user) { double("user", id: 7) }
      let(:event) { double("event", user:) }

      before do
        allow(Bot::Config).to receive(:owner_id).and_return("42")
      end

      it "grants access when the user holds every required permission" do
        allow(user).to receive(:permission?).with(:manage_messages).and_return(true)
        is_expected.to be(true)
      end

      it "denies access when the user lacks a required permission" do
        allow(user).to receive(:permission?).with(:manage_messages).and_return(false)
        is_expected.to be(false)
      end

      it "grants the owner access regardless of missing permissions" do
        allow(Bot::Config).to receive(:owner_id).and_return("7")
        is_expected.to be(true)
      end
    end
  end
end
