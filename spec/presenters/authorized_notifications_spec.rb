# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthorizedNotifications do
  let(:config_a) { create(:server_configuration, name: "Bravo Server") }
  let(:config_b) { create(:server_configuration, name: "Alpha Server") }
  let(:config_other) { create(:server_configuration) }

  let!(:notif_a1) { create(:notification, server_configuration: config_a) }
  let!(:notif_a2) { create(:notification, server_configuration: config_a) }
  let!(:notif_b1) { create(:notification, server_configuration: config_b) }
  let!(:notif_other) { create(:notification, server_configuration: config_other) }

  let(:manageable_ids) { [config_a.discord_id, config_b.discord_id] }

  subject(:authorized) { described_class.new(manageable_ids:) }

  describe "#groups" do
    it "excludes notifications from non-authorized servers" do
      all_notifications = authorized.groups.flat_map { |_c, ns| ns }
      expect(all_notifications).not_to include(notif_other)
    end

    it "includes notifications from authorized servers" do
      all_notifications = authorized.groups.flat_map { |_c, ns| ns }
      expect(all_notifications).to include(notif_a1, notif_a2, notif_b1)
    end

    it "groups by server configuration" do
      groups = authorized.groups
      expect(groups.map { |c, _| c }).to contain_exactly(config_a, config_b)
    end

    it "orders groups by server name alphabetically" do
      groups = authorized.groups
      expect(groups.map { |c, _| c.name }).to eq(["Alpha Server", "Bravo Server"])
    end

    context "when scoped to a server_id" do
      subject(:scoped) { described_class.new(manageable_ids:, server_id: config_a.discord_id) }

      it "returns one group for that server" do
        expect(scoped.groups.length).to eq(1)
      end

      it "returns only notifications for that server" do
        notifications = scoped.groups.flat_map { |_c, ns| ns }
        expect(notifications).to all(have_attributes(server_configuration: config_a))
      end

      it "returns empty when the server_id is not manageable" do
        other_scoped = described_class.new(manageable_ids:, server_id: config_other.discord_id)
        expect(other_scoped.groups).to be_empty
      end

      it "returns empty when server_id is manageable but no ServerConfiguration row exists" do
        phantom_id = 999_888_777
        phantom_scoped = described_class.new(manageable_ids: [phantom_id], server_id: phantom_id)
        expect(phantom_scoped.groups).to be_empty
      end
    end

    context "when a notification's server_configuration_id is not in the configs index" do
      it "skips the orphaned group via the next-unless-config guard" do
        # Force configs to return an empty hash while scoped still returns notifications.
        # This exercises the `next unless config` branch (a defensive guard).
        ordered_double = double("relation", index_by: {})
        relation_double = double("relation", order: ordered_double)
        allow(ServerConfiguration).to receive(:where).and_call_original
        allow(ServerConfiguration).to receive(:where).with(discord_id: manageable_ids).and_return(relation_double)

        groups = authorized.groups
        expect(groups).to be_empty
      end
    end

    context "when a notification is dismissed" do
      before { notif_a1.update!(dismissed_at: Time.current) }

      it "excludes dismissed notifications" do
        all_notifications = authorized.groups.flat_map { |_c, ns| ns }
        expect(all_notifications).not_to include(notif_a1)
      end
    end
  end

  describe "#unread_count" do
    it "counts unread notifications across authorized servers" do
      expect(authorized.unread_count).to eq(3)
    end

    it "excludes notifications from non-authorized servers" do
      all_authorized = described_class.new(manageable_ids: [config_a.discord_id, config_b.discord_id, config_other.discord_id])
      expect(all_authorized.unread_count).to eq(4)

      expect(authorized.unread_count).to eq(3)
    end

    context "when some notifications are already read" do
      before { notif_a1.update!(read_at: Time.current) }

      it "does not count read notifications" do
        expect(authorized.unread_count).to eq(2)
      end
    end

    context "when some notifications are dismissed" do
      before { notif_b1.update!(dismissed_at: Time.current) }

      it "does not count dismissed notifications" do
        expect(authorized.unread_count).to eq(2)
      end
    end
  end
end
