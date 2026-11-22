# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe "A stream moving between followed categories" do
  include_context "with a stream moving between followed categories"

  let(:post_job) { -> { Feeds::PostJob.perform_now(follow_b, updated_to_b) } }
  let(:revise) { -> { Ops::Feeds::Posts::Revise.call(post: card_of_a, event: updated_to_b) } }
  let(:holders) { Feeds::Post.where(story_key:).where.not(message_id: nil).pluck(:subscription_id) }

  def run_other_job_before_the_lock(other)
    armed = true
    allow(Feeds::StoryLock).to receive(:hold).and_wrap_original do |original, *args, &block|
      if armed
        armed = false
        other.call
      end
      original.call(*args, &block)
    end
  end

  before do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  def expect_one_card_moved
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to be_empty
    expect(Bot::Discord::Components).to have_received(:edit).once
    expect(Bot::Discord::Components).not_to have_received(:create_with_subject)
    expect(Bot::Discord::Components).not_to have_received(:delete_message)
    expect(holders).to eq([follow_b.id])
  end

  it "keeps one message when the announcement runs before the revision" do
    post_job.call
    revise.call

    expect_one_card_moved
  end

  it "keeps one message when the revision runs before the announcement" do
    revise.call
    post_job.call

    expect_one_card_moved
  end

  it "keeps one message when the revision gets in between the announcement's checks and its lock" do
    run_other_job_before_the_lock(revise)
    post_job.call

    expect_one_card_moved
  end

  it "keeps one message when the announcement gets in between the revision's read and its lock" do
    run_other_job_before_the_lock(post_job)
    revise.call

    expect_one_card_moved
  end
end
