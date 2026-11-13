# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationJob do
  let(:job_class) do
    Class.new(described_class) do
      def self.name
        "CommitProbeJob"
      end

      def perform
      end
    end
  end

  before do
    stub_const("CommitProbeJob", job_class)
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  context "when enqueued inside a transaction that commits" do
    subject(:queued_before_commit) do
      ActiveRecord::Base.transaction do
        job_class.perform_later
        queued.size
      end
    end

    it "reaches the queue only once the transaction commits" do
      expect(queued_before_commit).to eq(0)
      expect(queued.size).to eq(1)
    end
  end

  context "when enqueued inside a transaction that rolls back" do
    subject(:rolled_back) do
      ActiveRecord::Base.transaction do
        job_class.perform_later
        raise ActiveRecord::Rollback
      end
    end

    it "never reaches the queue" do
      rolled_back
      expect(queued).to be_empty
    end
  end

  def queued
    ActiveJob::Base.queue_adapter.enqueued_jobs.select { |job| job["job_class"] == "CommitProbeJob" }
  end
end
