require "rails_helper"

RSpec.describe Components::TomSelect do
  subject(:html) do
    described_class.new(
      name: "welcomes[channel_id]",
      options: [
        Components::TomSelect::Option.for(value: 111, label: "# general"),
        Components::TomSelect::Option.for(value: 222, label: "# announcements", disabled: true)
      ],
      selected: 111,
      placeholder: "Choose a channel",
      include_blank: true
    ).call
  end

  it "renders a select wired to the tom-select controller" do
    expect(html).to include("<select")
    expect(html).to include('name="welcomes[channel_id]"')
    expect(html).to include('data-controller="tom-select"')
    expect(html).to include('data-tom-select-placeholder-value="Choose a channel"')
  end

  it "renders a blank option for the placeholder" do
    expect(html).to include('value=""')
  end

  it "marks the selected option" do
    expect(html).to include('value="111"').and include("selected")
  end

  it "disables an option flagged disabled" do
    expect(html).to include('value="222"').and include("disabled")
  end

  context "without a placeholder or blank option" do
    subject(:plain) do
      described_class.new(
        name: "x",
        options: [Components::TomSelect::Option.for(value: 1, label: "one")]
      ).call
    end

    it "omits the blank option and the placeholder data attribute" do
      expect(plain).to include("<select")
      expect(plain).not_to include("tom-select-placeholder-value")
    end
  end
end
