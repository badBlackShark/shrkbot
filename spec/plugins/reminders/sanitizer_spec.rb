# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reminders::Sanitizer do
  describe ".call" do
    subject(:sanitized) { described_class.call(input) }

    context "with @everyone" do
      let(:input) { "@everyone hi" }

      it "neutralizes it but keeps the visible text" do
        expect(sanitized).not_to include("@everyone")
        expect(sanitized).to include("@")
        expect(sanitized).to include("everyone")
      end
    end

    context "with multiple @everyone" do
      let(:input) { "@everyone test @everyone" }

      it "neutralizes every instance" do
        expect(sanitized).not_to include("@everyone")
        expect(sanitized.scan("everyone").length).to eq(2)
      end
    end

    context "with @everyone at the start" do
      let(:input) { "@everyone please read" }

      it "still starts with @" do
        expect(sanitized).not_to include("@everyone")
        expect(sanitized).to start_with("@")
      end
    end

    context "with @here" do
      let(:input) { "@here listen up" }

      it "neutralizes it but keeps the visible text" do
        expect(sanitized).not_to include("@here")
        expect(sanitized).to include("@")
        expect(sanitized).to include("here")
      end
    end

    context "with multiple @here" do
      let(:input) { "@here first @here second" }

      it "neutralizes every instance" do
        expect(sanitized).not_to include("@here")
        expect(sanitized.scan("here").length).to eq(2)
      end
    end

    context "with both @everyone and @here" do
      let(:input) { "@everyone and @here" }

      it "neutralizes both" do
        expect(sanitized).not_to include("@everyone")
        expect(sanitized).not_to include("@here")
        expect(sanitized).to include("everyone")
        expect(sanitized).to include("here")
      end
    end

    context "with normal text" do
      let(:input) { "hello world" }
      it { is_expected.to eq("hello world") }
    end

    context "with a single @username" do
      let(:input) { "@john please help" }
      it { is_expected.to eq("@john please help") }
    end

    context "with a lone @" do
      let(:input) { "@ symbol here" }
      it { is_expected.to eq("@ symbol here") }
    end

    context "with several @username mentions" do
      let(:input) { "@alice @bob @charlie" }
      it { is_expected.to eq("@alice @bob @charlie") }
    end

    context "with nil" do
      let(:input) { nil }
      it { is_expected.to eq("") }
    end

    context "with an empty string" do
      let(:input) { "" }
      it { is_expected.to eq("") }
    end

    context "with @everyone followed by punctuation" do
      let(:input) { "@everyone!" }

      it "neutralizes the mention and keeps the punctuation" do
        expect(sanitized).not_to include("@everyone")
        expect(sanitized).to include("!")
      end
    end
  end
end
