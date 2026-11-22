# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::StoryLock do
  self.use_transactional_tests = false

  let(:server_configuration) { build_stubbed(:server_configuration) }

  def lock_free?(story_key)
    Thread.new {
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        key = "feeds-story:#{server_configuration.id}:#{story_key}"
        connection.select_value(
          ActiveRecord::Base.sanitize_sql_array(["SELECT pg_try_advisory_xact_lock(hashtext(?))", key])
        )
      end
    }.value
  end

  describe ".hold" do
    it "keeps other connections out of the same story while the block runs" do
      described_class.hold(server_configuration, "stream:1") do
        expect(lock_free?("stream:1")).to be(false)
      end
    end

    it "leaves other stories alone" do
      described_class.hold(server_configuration, "stream:1") do
        expect(lock_free?("stream:2")).to be(true)
      end
    end

    it "returns the block's value" do
      expect(described_class.hold(server_configuration, "stream:1") { :done }).to eq(:done)
    end
  end
end
