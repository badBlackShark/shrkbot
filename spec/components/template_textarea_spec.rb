# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::TemplateTextarea do
  subject(:html) { described_class.new(name: "t[x]", value: "Hi {title}", placeholder: "Default", data: {target: "x"}).call }

  it "renders the monospace field with name, value, placeholder and data" do
    expect(html).to include('name="t[x]"', 'placeholder="Default"', 'data-target="x"', 'rows="2"', "font-mono")
    expect(html).to include(">Hi {title}</textarea>")
  end
end
