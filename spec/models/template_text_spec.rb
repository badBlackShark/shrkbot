# frozen_string_literal: true

require "rails_helper"

RSpec.describe TemplateText do
  subject(:rendered) { described_class.render(template, tokens) }

  let(:template) { "Hello {name}!" }
  let(:tokens) { {name: "World"} }

  it "substitutes a known token" do
    expect(rendered).to eq("Hello World!")
  end

  context "with an unknown token in the template" do
    let(:template) { "Hello {name}, your {mystery} awaits." }

    it "leaves the unknown token literal in the output" do
      expect(rendered).to eq("Hello World, your {mystery} awaits.")
    end
  end

  context "with a backreference sequence in the substituted value" do
    let(:tokens) { {name: 'Sm\\1oke'} }

    it "inserts the value literally instead of expanding the sequence" do
      expect(rendered).to eq('Hello Sm\\1oke!')
    end
  end

  context "with a substituted value containing token-like braces" do
    let(:template) { "{alpha} and {beta}" }
    let(:tokens) { {alpha: "literal", beta: "{alpha}"} }

    it "does not re-substitute the already-processed token" do
      expect(rendered).to eq("literal and {alpha}")
    end
  end

  context "with a non-String value" do
    let(:template) { "Count: {count}" }
    let(:tokens) { {count: 42} }

    it "renders the value via to_s" do
      expect(rendered).to eq("Count: 42")
    end
  end

  context "with a nil template" do
    let(:template) { nil }

    it "renders empty" do
      expect(rendered).to eq("")
    end
  end

  context "with a token appearing twice" do
    let(:template) { "{name} meet {name}" }

    it "substitutes both occurrences" do
      expect(rendered).to eq("World meet World")
    end
  end
end
