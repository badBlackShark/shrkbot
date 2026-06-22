require "rails_helper"

RSpec.describe Components::TurboStream do
  subject(:html) do
    described_class.new
      .replace("plugin-roles", Components::Toast.new(level: "notice", message: "Saved"))
      .append("toasts", Components::Toast.new(level: "alert", message: "Nope"))
      .call
  end

  it "wraps each operation in a turbo-stream element targeting the right id" do
    expect(html).to include('<turbo-stream action="replace" target="plugin-roles">')
    expect(html).to include('<turbo-stream action="append" target="toasts">')
  end

  it "renders each component inside a template" do
    expect(html).to include("<template>").and include("Saved").and include("Nope")
  end
end
