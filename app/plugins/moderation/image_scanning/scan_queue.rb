# frozen_string_literal: true

module Moderation
  module ImageScanning
    class ScanQueue
      INSTANCE_MUTEX = Mutex.new

      def self.instance
        INSTANCE_MUTEX.synchronize { @instance ||= new }
      end

      def self.enqueue(author_id, job)
        instance.enqueue(author_id, job)
      end

      def initialize(per_author: 500, workers: 2)
        @per_author = per_author
        @workers = workers
        @waiting = {}
        @ready = Queue.new
        @mutex = Mutex.new
        @started = false
      end

      def enqueue(author_id, job)
        @mutex.synchronize do
          start_workers
          jobs = @waiting[author_id]
          if jobs.nil?
            @waiting[author_id] = [job]
            @ready << author_id
          elsif jobs.size < @per_author
            jobs << job
          else
            Rails.logger.error("[Moderation::ImageScanning::ScanQueue] author #{author_id} has #{@per_author} scans waiting, dropping scan job")
          end
        end
      end

      private

      def start_workers
        return if @started

        @started = true
        @workers.times { spawn_worker }
      end

      def spawn_worker
        Thread.new do
          loop { run(@ready.pop) }
        end
      end

      def run(author_id)
        job = @mutex.synchronize { @waiting[author_id].shift }
        job.call
      rescue => e
        Rails.logger.error("[Moderation::ImageScanning::ScanQueue] worker crashed: #{e.class}: #{e.message}")
      ensure
        requeue(author_id)
      end

      def requeue(author_id)
        @mutex.synchronize do
          if @waiting[author_id].empty?
            @waiting.delete(author_id)
          else
            @ready << author_id
          end
        end
      end
    end
  end
end
