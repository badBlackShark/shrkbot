# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportsExhaustion do
  subject(:attempt) { ActiveJob::Base.execute(serialized) }

  let(:job_class) do
    Class.new(ApplicationJob) do
      include ReportsExhaustion

      def self.name
        "FlakyJob"
      end

      def perform
        raise "discord is down"
      end
    end
  end
  let(:prior_attempts) { 0 }
  let(:serialized) do
    job_class.new.serialize.merge("executions" => prior_attempts, "exception_executions" => {"[StandardError]" => prior_attempts})
  end

  before do
    allow(ReportExhaustedJob).to receive(:perform_later)
    stub_const("FlakyJob", job_class)
  end

  context "when attempts remain" do
    let(:prior_attempts) { ReportsExhaustion::ATTEMPTS - 2 }

    it "retries without reporting" do
      expect { attempt }.to have_enqueued_job(job_class)
      expect(ReportExhaustedJob).not_to have_received(:perform_later)
    end
  end

  context "when the last attempt fails" do
    let(:prior_attempts) { ReportsExhaustion::ATTEMPTS - 1 }

    it "reports the give-up to the owner and re-raises" do
      expect { attempt }.to raise_error("discord is down")

      expect(ReportExhaustedJob).to have_received(:perform_later).once.with(a_string_matching(/\AFlakyJob \S+: RuntimeError: discord is down\z/))
    end
  end

  it "gives up before the owner DM does, so the DM outlives the outage that exhausted the job" do
    expect(NotifiesOwner::ATTEMPTS).to be > described_class::ATTEMPTS
  end
end
