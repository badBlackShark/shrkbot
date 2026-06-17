require "rails_helper"

RSpec.describe WithConnection do
  let(:obj) { Class.new { include WithConnection }.new }

  subject(:result) { obj.with_connection { block_value } }

  context "with a simple value" do
    let(:block_value) { 7 }

    it "yields and returns the block's value" do
      expect(result).to eq(7)
    end
  end

  context "with a connection check" do
    let(:block_value) { ActiveRecord::Base.connection.active? }

    it "runs the block with a live AR connection (checked out of the pool)" do
      expect(result).to be(true)
    end
  end
end
