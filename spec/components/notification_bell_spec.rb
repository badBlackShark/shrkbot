# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::NotificationBell do
  include_context "component view context"

  let(:config) { create(:server_configuration) }
  let(:manageable_ids) { [config.discord_id] }
  let(:authorized) { AuthorizedNotifications.new(manageable_ids:) }

  subject(:html) { described_class.new(authorized:).render_in(view_context) }

  context "when unread_count is zero" do
    it "renders the bell aria-label without a count" do
      expect(html).to include("aria-label")
      expect(html).not_to include("unread notification")
    end

    it "does not render the unread badge" do
      # The badge span has a distinctive class that only appears when count > 0
      expect(html).not_to include("bg-accent-fill")
    end
  end

  context "when there are unread notifications" do
    let!(:notification) do
      create(
        :notification,
        server_configuration: config,
        read_at: nil,
        data: {"plugin_key" => "logging", "plugin_name" => "Logging", "channel_name" => "general"}
      )
    end

    it "renders the unread badge" do
      expect(html).to include("bg-accent-fill")
    end

    it "renders the notification count in the badge" do
      expect(html).to include("1")
    end

    it "includes the summary element with aria-label" do
      expect(html).to include("aria-label")
    end
  end
end
