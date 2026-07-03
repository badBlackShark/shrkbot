# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TomSelect do
  subject(:html) do
    described_class.new(
      name: "welcomes[channel_id]",
      options: [
        Components::TomSelect::Option.for(value: 111, label: "general"),
        Components::TomSelect::Option.for(value: 222, label: "announcements", disabled: true)
      ],
      selected: 111,
      include_blank: true
    ).call
  end

  it "renders a select wired to the tom-select controller" do
    expect(html).to include("<select")
    expect(html).to include('name="welcomes[channel_id]"')
    expect(html).to include('data-controller="tom-select"')
  end

  it "renders a blank option when include_blank is set" do
    expect(html).to include('value=""')
  end

  it "marks the selected option" do
    expect(html).to include('value="111"').and include("selected")
  end

  it "disables an option flagged disabled" do
    expect(html).to include('value="222"').and include("disabled")
  end

  it "merges caller-supplied controller data onto the select" do
    html = described_class.new(name: "x", options: [], controller_data: {tom_select_prefix_value: "#"}).call
    expect(html).to include('data-tom-select-prefix-value="#"')
  end

  it "renders a multi-select when asked" do
    html = described_class.new(name: "x", options: [], multiple: true).call
    expect(html).to include("multiple")
  end

  context "with per-option adornment data" do
    subject(:adorned) do
      described_class.new(
        name: "roles[]",
        options: [
          Components::TomSelect::Option.for(value: 1, label: "Admin", color: "#37a79e"),
          Components::TomSelect::Option.for(value: 2, label: "Plain")
        ]
      ).call
    end

    it "emits data-* attributes Tom Select copies onto the option for colour or a reason" do
      expect(adorned).to include('data-color="#37a79e"')
    end

    it "leaves plain options without adornment attributes" do
      plain = described_class.new(name: "x", options: [Components::TomSelect::Option.for(value: 2, label: "Plain")]).call
      expect(plain).to include(">Plain<")
      expect(plain).not_to include("data-color")
    end
  end
end
