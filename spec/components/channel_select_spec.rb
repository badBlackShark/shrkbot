# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ChannelSelect do
  subject(:html) do
    described_class.new(
      name: "welcomes[channel_id]",
      options: [Components::TomSelect::Option.for(value: 111, label: "general")],
      selected: 111,
      placeholder: "Choose a channel",
      include_blank: true
    ).call
  end

  it "renders a single channel select with the # prefix adornment" do
    expect(html).to include("<select")
    expect(html).not_to include("multiple")
    expect(html).to include('data-tom-select-prefix-value="#"')
  end

  it "passes the placeholder through to the controller" do
    expect(html).to include('data-tom-select-placeholder-value="Choose a channel"')
  end

  it "keeps the prefix out of the option label" do
    expect(html).to include(">general<")
    expect(html).not_to include("# general")
  end

  it "renders a blank option when include_blank is set" do
    expect(html).to include('value=""')
  end

  context "when multiple is true" do
    subject(:html) do
      described_class.new(
        name: "lfg[allowed_channel_ids][]",
        options: [Components::TomSelect::Option.for(value: 111, label: "general")],
        selected: [111],
        placeholder: "Choose channels",
        multiple: true
      ).call
    end

    it "renders a select with the multiple attribute" do
      expect(html).to include("<select")
      expect(html).to include("multiple")
    end
  end
end
