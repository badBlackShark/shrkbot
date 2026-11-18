# frozen_string_literal: true

require "rails_helper"

RSpec.describe "app/assets/builds/tailwind.css" do
  subject(:dead_selectors) do
    Rails.root.join("app/assets/builds/tailwind.css").read
      .scan(/[^{},]*:(?:is|where|has|not)\(\)[^{},]*/)
  end

  it "has no empty selector list, which Tailwind emits for an arbitrary value it misreads and which never matches" do
    expect(dead_selectors).to be_empty
  end
end
