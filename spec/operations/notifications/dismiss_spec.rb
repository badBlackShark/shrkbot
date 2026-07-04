# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Notifications::Dismiss do
  include ActiveSupport::Testing::TimeHelpers

  let(:notification) { create(:notification) }

  subject(:result) { described_class.call(notification:) }

  it "sets dismissed_at" do
    travel_to(Time.current) do
      result
      expect(notification.reload.dismissed_at).to eq(Time.current)
    end
  end

  it "returns the notification in result.value" do
    expect(result.value).to eq(notification)
  end

  it "returns a success result" do
    expect(result).to be_success
  end
end
