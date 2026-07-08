# frozen_string_literal: true

require "rails_helper"
require "timeout"

RSpec.describe Moderation::ScanQueue do
  describe "dropping jobs when the queue is full" do
    subject(:queue) { described_class.new(size: 1, workers: 1) }

    let(:ready) { Queue.new }
    let(:release) { Queue.new }
    let(:ran) { Queue.new }

    let(:blocking_job) do
      lambda do
        ready << :running
        release.pop
      end
    end

    let(:filler_job) { lambda { release.pop } }
    let(:dropped_job) { lambda { ran << :ran } }

    after do
      release << :go
      release << :go
    end

    it "logs and drops the job instead of running it" do
      allow(Rails.logger).to receive(:warn)

      queue.enqueue(blocking_job)
      Timeout.timeout(2) { ready.pop }

      queue.enqueue(filler_job)

      expect(Rails.logger).to receive(:warn).with(/queue full/)
      queue.enqueue(dropped_job)

      expect(ran).to be_empty
    end
  end

  describe ".instance" do
    it "memoizes a single process-wide instance" do
      expect(described_class.instance).to be_a(described_class)
      expect(described_class.instance).to equal(described_class.instance)
    end
  end

  describe ".enqueue" do
    let(:singleton) { instance_double(described_class, enqueue: nil) }

    before { allow(described_class).to receive(:instance).and_return(singleton) }

    it "delegates to the singleton instance so callers need not reach for .instance" do
      job = -> {}
      described_class.enqueue(job)
      expect(singleton).to have_received(:enqueue).with(job)
    end
  end

  describe "isolating worker crashes" do
    subject(:queue) { described_class.new(size: 5, workers: 1) }

    let(:done) { Queue.new }
    let(:crashing_job) { lambda { raise "boom" } }
    let(:surviving_job) { lambda { done << :ok } }

    before do
      allow(Rails.logger).to receive(:error)
    end

    it "keeps the worker alive after a job raises" do
      queue.enqueue(crashing_job)
      queue.enqueue(surviving_job)

      expect(Timeout.timeout(2) { done.pop }).to eq(:ok)
    end
  end
end
