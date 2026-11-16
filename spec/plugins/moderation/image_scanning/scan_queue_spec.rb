# frozen_string_literal: true

require "rails_helper"
require "timeout"

RSpec.describe Moderation::ImageScanning::ScanQueue do
  let(:ready) { Queue.new }
  let(:release) { Queue.new }
  let(:ran) { Queue.new }
  let(:done) { Queue.new }

  let(:blocking_job) do
    lambda do
      ready << :running
      release.pop
    end
  end

  after do
    release << :go
    release << :go
  end

  describe "running jobs" do
    subject(:queue) { described_class.new(workers: 1) }

    it "runs a queued job" do
      queue.enqueue(1, -> { done << :ok })

      expect(Timeout.timeout(2) { done.pop }).to eq(:ok)
    end
  end

  describe "taking turns between authors" do
    subject(:queue) { described_class.new(workers: 1) }

    let(:order) { Queue.new }
    let(:first_job) do
      lambda do
        order << :a1
        ready << :running
        release.pop
      end
    end

    before do
      queue.enqueue(1, first_job)
      Timeout.timeout(2) { ready.pop }
      queue.enqueue(1, -> { order << :a2 })
      queue.enqueue(1, -> { order << :a3 })
      queue.enqueue(2, -> { order << :b1 })
      release << :go
    end

    it "serves the second author before the first author's backlog" do
      served = Array.new(4) { Timeout.timeout(2) { order.pop } }

      expect(served).to eq([:a1, :b1, :a2, :a3])
    end
  end

  describe "one lane per author" do
    subject(:queue) { described_class.new(workers: 2) }

    before do
      queue.enqueue(1, blocking_job)
      Timeout.timeout(2) { ready.pop }
      queue.enqueue(1, -> { ran << :a2 })
      queue.enqueue(2, -> { ran << :b1 })
    end

    it "never runs two jobs of one author at once" do
      expect(Timeout.timeout(2) { ran.pop }).to eq(:b1)
      expect(ran).to be_empty
    end
  end

  describe "dropping jobs when an author's lane is full" do
    subject(:queue) { described_class.new(per_author: 1, workers: 1) }

    before do
      queue.enqueue(1, blocking_job)
      Timeout.timeout(2) { ready.pop }
      queue.enqueue(1, -> { ran << :a2 })
    end

    it "logs and drops the job instead of running it" do
      expect(Rails.logger).to receive(:error).with(/author 1 has 1 scans waiting/)
      queue.enqueue(1, -> { ran << :a3 })

      expect(ran).to be_empty
    end

    it "still accepts another author" do
      allow(Rails.logger).to receive(:error)
      queue.enqueue(1, -> { ran << :a3 })
      queue.enqueue(2, -> { done << :b1 })
      release << :go

      expect(Timeout.timeout(2) { done.pop }).to eq(:b1)
    end
  end

  describe "isolating worker crashes" do
    subject(:queue) { described_class.new(workers: 1) }

    before do
      allow(Rails.logger).to receive(:error)
    end

    it "keeps the worker and the author's lane alive after a job raises" do
      queue.enqueue(1, -> { raise "boom" })
      queue.enqueue(1, -> { done << :ok })

      expect(Timeout.timeout(2) { done.pop }).to eq(:ok)
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
      described_class.enqueue(7, job)
      expect(singleton).to have_received(:enqueue).with(7, job)
    end
  end
end
