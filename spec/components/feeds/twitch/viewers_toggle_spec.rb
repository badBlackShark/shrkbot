# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Twitch::ViewersToggle do
  include_context "component view context"

  subject(:html) { described_class.new(subscription:).render_in(view_context) }

  let(:subscription) { build(:feed_subscription, :twitch) }

  it "marks the checkbox itself so the preview can follow it" do
    expect(html).to match(/<input type="checkbox"[^>]*data-viewers-toggle>/)
  end
end
