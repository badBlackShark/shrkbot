# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roles::MenuSyncPlan do
  subject(:plan) { described_class.new }

  before do
    allow(ConfigBus).to receive(:delete_roles_message)
    allow(ConfigBus).to receive(:remove_roles_menu)
    allow(ConfigBus).to receive(:post_roles)
  end

  describe "#publish" do
    context "with a delete, a remove, and a post" do
      let(:set) { create(:role_set, message_id: 999) }
      let(:remove_set) { create(:role_set, message_id: 888) }

      before do
        plan.delete(channel_id: 123, message_id: 456)
        plan.remove(remove_set)
        plan.post(set)
      end

      it "publishes in order: deletes, then removes, then posts" do
        order = []
        allow(ConfigBus).to receive(:delete_roles_message) { order << :delete }
        allow(ConfigBus).to receive(:remove_roles_menu) { order << :remove }
        allow(ConfigBus).to receive(:post_roles) { order << :post }

        plan.publish

        expect(order).to eq([:delete, :remove, :post])
      end

      it "passes the channel and message ids to ConfigBus.delete_roles_message" do
        plan.publish
        expect(ConfigBus).to have_received(:delete_roles_message).with(channel_id: 123, message_id: 456)
      end

      it "passes the remove set to ConfigBus.remove_roles_menu" do
        plan.publish
        expect(ConfigBus).to have_received(:remove_roles_menu).with(remove_set)
      end

      it "passes the set to ConfigBus.post_roles" do
        plan.publish
        expect(ConfigBus).to have_received(:post_roles).with(set)
      end
    end

    context "when channel_id is nil" do
      before { plan.delete(channel_id: nil, message_id: 456) }

      it "skips the delete" do
        plan.publish
        expect(ConfigBus).not_to have_received(:delete_roles_message)
      end
    end

    context "when message_id is nil" do
      before { plan.delete(channel_id: 123, message_id: nil) }

      it "skips the delete" do
        plan.publish
        expect(ConfigBus).not_to have_received(:delete_roles_message)
      end
    end
  end
end
