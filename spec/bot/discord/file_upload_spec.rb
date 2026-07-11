# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::Discord::FileUpload do
  subject(:io) { described_class.new("fakepngbytes", "image.png") }

  describe "#path" do
    it "returns the filename" do
      expect(io.path).to eq("image.png")
    end
  end

  describe "#original_filename" do
    it "returns the filename" do
      expect(io.original_filename).to eq("image.png")
    end
  end

  describe "#read" do
    it "returns the bytes" do
      expect(io.read).to eq("fakepngbytes")
    end
  end
end
