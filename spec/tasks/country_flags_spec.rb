# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "twilight_struggle:upload_country_flags" do
  subject(:run_task) { task.invoke }

  let(:task) { Rake::Task["twilight_struggle:upload_country_flags"] }
  let(:uploaded) { {} }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    task.reenable

    allow(Bot::Discord::ApplicationEmoji).to receive(:reset!)
    allow(Bot::Discord::ApplicationEmoji).to receive(:ids) { uploaded }
    allow(Bot::Discord::ApplicationEmoji).to receive(:upload)
    allow($stdout).to receive(:puts)
  end

  it "uploads every regional flag the application does not carry yet" do
    run_task

    expect(Bot::Discord::ApplicationEmoji).to have_received(:upload)
      .exactly(TwilightStruggle::CountryFlag.custom_emoji_names.size).times
  end

  it "uploads each flag from its own image" do
    run_task

    expect(Bot::Discord::ApplicationEmoji).to have_received(:upload)
      .with("catalonia", Rails.root.join("config/country_flag_images/catalonia.png"))
  end

  it "skips a flag the application already carries" do
    uploaded["catalonia"] = "42"

    run_task

    expect(Bot::Discord::ApplicationEmoji).not_to have_received(:upload).with("catalonia", anything)
  end

  it "ships an image for every regional flag it would upload" do
    missing = TwilightStruggle::CountryFlag.custom_emoji_names.reject do |emoji_name|
      TwilightStruggle::CountryFlag.image_path(emoji_name).exist?
    end

    expect(missing).to be_empty
  end
end
