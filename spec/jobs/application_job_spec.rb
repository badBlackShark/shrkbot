# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationJob do
  let(:job_class) {
    stub_const("CommitProbeJob", Class.new(described_class) {
      def perform
      end
    })
  }

  before do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  def queued
    ActiveJob::Base.queue_adapter.enqueued_jobs.select { |job| job["job_class"] == "CommitProbeJob" }
  end

  context "when enqueued inside a transaction that commits" do
    subject(:commit_enqueue) do
      ActiveRecord::Base.transaction do
        job_class.perform_later
        queued.size
      end
    end

    it "reaches the queue only once the transaction commits" do
      expect(commit_enqueue).to eq(0)
      expect(queued.size).to eq(1)
    end
  end

  context "when enqueued inside a transaction that rolls back" do
    subject(:rollback_enqueue) do
      ActiveRecord::Base.transaction do
        job_class.perform_later
        raise ActiveRecord::Rollback
      end
    end

    it "never reaches the queue" do
      rollback_enqueue
      expect(queued).to be_empty
    end
  end
end
