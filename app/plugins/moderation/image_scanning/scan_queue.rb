# frozen_string_literal: true

module Moderation
  module ImageScanning
    class ScanQueue
      INSTANCE_MUTEX = Mutex.new

      def self.instance
        INSTANCE_MUTEX.synchronize { @instance ||= new }
      end

      def self.enqueue(job)
        instance.enqueue(job)
      end

      def initialize(size: 10, workers: 2)
        @queue = SizedQueue.new(size)
        @workers = workers
        @mutex = Mutex.new
        @started = false
      end

      def enqueue(job)
        ensure_workers
        @queue.push(job, true)
      rescue ThreadError
        Rails.logger.warn("[Moderation::ImageScanning::ScanQueue] queue full, dropping scan job")
      end

      private

      def ensure_workers
        @mutex.synchronize do
          return if @started
          @started = true
          @workers.times { spawn_worker }
        end
      end

      def spawn_worker
        Thread.new do
          loop do
            job = @queue.pop
            job.call
          rescue => e
            Rails.logger.error("[Moderation::ImageScanning::ScanQueue] worker crashed: #{e.class}: #{e.message}")
          end
        end
      end
    end
  end
end
