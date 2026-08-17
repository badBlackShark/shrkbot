# frozen_string_literal: true

require "rails_helper"

RSpec.describe Finders::AuthorizedNotifications do
  let(:config_a) { create(:server_configuration, name: "Bravo Server") }
  let(:config_b) { create(:server_configuration, name: "Alpha Server") }
  let(:config_other) { create(:server_configuration) }

  let!(:notif_a1) { create(:notification, server_configuration: config_a) }
  let!(:notif_a2) { create(:notification, server_configuration: config_a) }
  let!(:notif_b1) { create(:notification, server_configuration: config_b) }
  let!(:notif_other) { create(:notification, server_configuration: config_other) }

  let(:manageable_ids) { [config_a.discord_id, config_b.discord_id] }

  let(:authorized) { described_class.new(manageable_ids:) }

  describe "#groups" do
    subject(:groups) { authorized.groups }

    let(:notifications) { groups.flat_map { |_config, group| group } }

    it "excludes notifications from non-authorized servers" do
      expect(notifications).not_to include(notif_other)
    end

    it "includes notifications from authorized servers" do
      expect(notifications).to include(notif_a1, notif_a2, notif_b1)
    end

    it "groups by server configuration" do
      expect(groups.map { |config, _| config }).to contain_exactly(config_a, config_b)
    end

    it "orders groups by server name alphabetically" do
      expect(groups.map { |config, _| config.name }).to eq(["Alpha Server", "Bravo Server"])
    end

    context "when scoped to a server_id" do
      let(:authorized) { described_class.new(manageable_ids:, server_id:) }
      let(:server_id) { config_a.discord_id }

      it "returns one group for that server" do
        expect(groups.length).to eq(1)
      end

      it "returns only notifications for that server" do
        expect(notifications).to all(have_attributes(server_configuration: config_a))
      end

      context "when the server_id is not manageable" do
        let(:server_id) { config_other.discord_id }

        it "returns empty" do
          expect(groups).to be_empty
        end
      end

      context "when the server_id is manageable but has no ServerConfiguration row" do
        let(:manageable_ids) { [999_888_777] }
        let(:server_id) { 999_888_777 }

        it "returns empty" do
          expect(groups).to be_empty
        end
      end
    end

    context "when a notification is dismissed" do
      before { notif_a1.update!(dismissed_at: Time.current) }

      it "excludes dismissed notifications" do
        expect(notifications).not_to include(notif_a1)
      end
    end
  end

  describe "#unread_count" do
    subject(:unread_count) { authorized.unread_count }

    it "counts unread notifications across authorized servers" do
      expect(unread_count).to eq(3)
    end

    context "when every server is manageable" do
      let(:manageable_ids) { [config_a.discord_id, config_b.discord_id, config_other.discord_id] }

      it "also counts the server the narrower scope excluded" do
        expect(unread_count).to eq(4)
      end
    end

    context "when some notifications are already read" do
      before { notif_a1.update!(read_at: Time.current) }

      it "does not count read notifications" do
        expect(unread_count).to eq(2)
      end
    end

    context "when some notifications are dismissed" do
      before { notif_b1.update!(dismissed_at: Time.current) }

      it "does not count dismissed notifications" do
        expect(unread_count).to eq(2)
      end
    end
  end
end
