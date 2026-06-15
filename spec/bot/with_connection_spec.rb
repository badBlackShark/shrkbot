require "rails_helper"

RSpec.describe WithConnection do
  let(:obj) { Class.new { include WithConnection }.new }

  it "yields and returns the block's value" do
    expect(obj.with_connection { 7 }).to eq(7)
  end

  it "runs the block with a live AR connection (checked out of the pool)" do
    expect(obj.with_connection { ActiveRecord::Base.connection.active? }).to be(true)
  end
end
