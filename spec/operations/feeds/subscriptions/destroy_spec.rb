# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Feeds::Subscriptions::Destroy do
  subject(:result) { described_class.call(subscription:) }

  let!(:subscription) { create(:feed_subscription) }
  let!(:event) { create(:feed_subscribed_event, subscription:) }

  it "deletes the subscription and its subscribed events" do
    expect { result }.to change(Feeds::Subscription, :count).by(-1).and change(Feeds::SubscribedEvent, :count).by(-1)
  end

  it "leaves the watch for the orphan prune" do
    expect { result }.not_to change(Integrations::Watch, :count)
  end
end
