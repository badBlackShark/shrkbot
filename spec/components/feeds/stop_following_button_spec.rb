# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::StopFollowingButton do
  include_context "component view context"

  subject(:labels) do
    subscriptions.map do |subscription|
      html = described_class.new(subscription:, compact: true).render_in(view_context)
      Nokogiri::HTML5.fragment(html).at_css("a")["aria-label"]
    end
  end

  let(:subscriptions) do
    [
      create(:feed_subscription, watch: create(:integration_watch, name: "Hades II")),
      create(:feed_subscription, watch: create(:integration_watch, name: "Balatro"))
    ]
  end

  it "names the game in each row's accessible label" do
    expect(labels).to eq(["Stop following Hades II", "Stop following Balatro"])
  end
end
