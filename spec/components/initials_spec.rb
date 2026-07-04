# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Initials do
  let(:host) do
    Class.new do
      include Components::Initials

      public :initials
    end.new
  end

  it "returns first two initials for a multi-word name" do
    expect(host.initials("Foo Bar Baz")).to eq("FB")
  end

  it "returns single initial for a one-word name" do
    expect(host.initials("single")).to eq("S")
  end

  it "caps at two characters even with four words" do
    expect(host.initials("a b c d")).to eq("AB")
  end
end
