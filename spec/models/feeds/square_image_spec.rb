# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::SquareImage do
  subject(:square) { Vips::Image.new_from_buffer(described_class.call(bytes), "") }

  let(:width) { 374 }
  let(:height) { 448 }
  let(:bytes) { Vips::Image.black(width, height).add(200).cast(:uchar).jpegsave_buffer }

  def alpha_at(image, x, y)
    image.getpoint(x, y).last
  end

  it "pads the shorter side up to a square" do
    expect([square.width, square.height]).to eq([448, 448])
  end

  it "adds an alpha channel" do
    expect(square.has_alpha?).to be(true)
  end

  it "leaves the padding transparent and the picture opaque" do
    expect(alpha_at(square, 0, 0)).to eq(0)
    expect(alpha_at(square, 224, 224)).to eq(255)
  end

  context "with a landscape image" do
    let(:width) { 460 }
    let(:height) { 215 }

    it "pads the height instead" do
      expect([square.width, square.height]).to eq([460, 460])
    end

    it "leaves the padding transparent and the picture opaque" do
      expect(alpha_at(square, 230, 0)).to eq(0)
      expect(alpha_at(square, 230, 230)).to eq(255)
    end
  end
end
