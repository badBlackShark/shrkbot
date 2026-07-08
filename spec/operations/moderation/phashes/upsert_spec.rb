# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::Phashes::Upsert do
  it "requires subclasses to implement #verdict" do
    expect { described_class.new.send(:verdict) }.to raise_error(AbstractMethodError)
  end
end
