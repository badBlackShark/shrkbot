# frozen_string_literal: true

require "rails_helper"

RSpec.describe "package.json" do
  subject(:test_version) do
    JSON.parse(Rails.root.join("package.json").read).dig("devDependencies", "@hotwired/stimulus")
  end

  let(:shipped_version) do
    Pathname(Gem.loaded_specs["stimulus-rails"].full_gem_path)
      .join("app/assets/javascripts/stimulus.js").read[/Stimulus (\d+\.\d+\.\d+)/, 1]
  end

  it "pins the Stimulus the stimulus-rails gem ships, so the JS tests drive what the browser runs" do
    expect(test_version).to eq(shipped_version)
  end
end
