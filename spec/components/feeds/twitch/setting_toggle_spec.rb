# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Twitch::SettingToggle do
  include_context "component view context"

  subject(:html) { described_class.new(subscription:, setting:, marker: "image", label: "Show a thing").render_in(view_context) }

  let(:subscription) { build(:feed_subscription, :twitch) }
  let(:setting) { :show_clips_thumbnail }

  it "marks the checkbox itself so the preview can follow it" do
    expect(html).to match(/<input type="checkbox"[^>]*data-setting-toggle="image"/)
  end

  it "labels the toggle and checks it by default" do
    expect(html).to include("Show a thing")
    expect(html).to match(/<input type="checkbox"[^>]*name="subscription\[show_clips_thumbnail\]"[^>]*checked/)
  end

  context "when the follow has it off" do
    before do
      subscription.settings.show_clips_thumbnail = false
    end

    it "leaves the checkbox unchecked" do
      expect(html).not_to match(/<input type="checkbox"[^>]*checked/)
    end
  end
end
