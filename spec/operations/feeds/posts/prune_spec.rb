# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Feeds::Posts::Prune do
  subject(:result) { described_class.call }

  let!(:old_post) { create(:feed_post, created_at: 15.days.ago) }
  let!(:recent_post) { create(:feed_post, created_at: 13.days.ago) }

  it "deletes posts older than 14 days" do
    result

    expect(Feeds::Post.exists?(old_post.id)).to be(false)
  end

  it "keeps newer ones" do
    result

    expect(Feeds::Post.exists?(recent_post.id)).to be(true)
  end
end
