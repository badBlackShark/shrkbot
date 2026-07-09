# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ComponentActions do
  subject(:handler) { includer.new(event) }

  let(:includer) do
    Class.new(BaseEvent) do
      include Moderation::ComponentActions
    end
  end

  let(:guild_id) { 111 }
  let(:user_id) { 222 }
  let(:staff_role_id) { 333 }

  let!(:config) { create(:server_configuration, discord_id: guild_id) }

  let(:server) { double("server", id: guild_id) }
  let(:user) { double("user", id: user_id) }
  let(:roles) { [] }
  let(:manage_messages) { false }
  let(:member) { double("member", roles:, permission?: manage_messages) }
  let(:event) { double("event", server:, user:, custom_id: "mod:confirm:deadbeefdeadbeef") }

  before do
    allow(server).to receive(:member).with(user_id).and_return(member) if server
  end

  describe "#server_configuration" do
    it "loads the guild's config and memoizes it" do
      first = handler.send(:server_configuration)
      expect(first).to eq(config)
      expect(handler.send(:server_configuration)).to be(first)
    end

    context "when the interaction has no server" do
      let(:server) { nil }

      it "is nil" do
        expect(handler.send(:server_configuration)).to be_nil
      end
    end
  end

  describe "#member" do
    it "resolves and memoizes the acting member" do
      expect(handler.send(:member)).to eq(member)
      expect(handler.send(:member)).to eq(member)
    end

    context "when the interaction has no server" do
      let(:server) { nil }

      it "is nil" do
        expect(handler.send(:member)).to be_nil
      end
    end
  end

  describe "#authorized?" do
    context "when the member cannot be resolved" do
      before { allow(server).to receive(:member).with(user_id).and_return(nil) }

      it "is false" do
        expect(handler.send(:authorized?)).to be(false)
      end
    end

    context "when the member holds the configured staff role" do
      let!(:settings) { create(:moderation_settings, server_configuration: config, staff_role_id:) }
      let(:roles) { [double("role", id: staff_role_id)] }

      it "is true" do
        expect(handler.send(:authorized?)).to be(true)
      end
    end

    context "when no staff role is configured but the member has Manage Messages" do
      let(:manage_messages) { true }

      it "is true" do
        expect(handler.send(:authorized?)).to be(true)
      end
    end

    context "when the guild has no stored configuration" do
      let(:server) { double("server", id: 999) }
      let(:manage_messages) { true }

      it "falls back to the Manage Messages permission" do
        expect(handler.send(:authorized?)).to be(true)
      end
    end

    context "when the staff role is configured but the member lacks it and Manage Messages" do
      let!(:settings) { create(:moderation_settings, server_configuration: config, staff_role_id:) }

      it "is false" do
        expect(handler.send(:authorized?)).to be(false)
      end
    end
  end
end
