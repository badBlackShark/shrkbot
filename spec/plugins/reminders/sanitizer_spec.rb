require "rails_helper"

RSpec.describe Reminders::Sanitizer do
  describe ".call" do
    context "with @everyone" do
      it "neutralizes @everyone with zero-width space" do
        result = Reminders::Sanitizer.call("@everyone hi")
        expect(result).not_to include("@everyone")
        expect(result).to include("@")
        expect(result).to include("everyone")
      end

      it "neutralizes multiple @everyone instances" do
        result = Reminders::Sanitizer.call("@everyone test @everyone")
        expect(result).not_to include("@everyone")
        expect(result.scan("everyone").length).to eq(2)
      end

      it "handles @everyone at the start" do
        result = Reminders::Sanitizer.call("@everyone please read")
        expect(result).not_to include("@everyone")
        expect(result).to start_with("@")
      end
    end

    context "with @here" do
      it "neutralizes @here with zero-width space" do
        result = Reminders::Sanitizer.call("@here listen up")
        expect(result).not_to include("@here")
        expect(result).to include("@")
        expect(result).to include("here")
      end

      it "neutralizes multiple @here instances" do
        result = Reminders::Sanitizer.call("@here first @here second")
        expect(result).not_to include("@here")
        expect(result.scan("here").length).to eq(2)
      end
    end

    context "with both @everyone and @here" do
      it "neutralizes both in the same string" do
        result = Reminders::Sanitizer.call("@everyone and @here")
        expect(result).not_to include("@everyone")
        expect(result).not_to include("@here")
        expect(result).to include("everyone")
        expect(result).to include("here")
      end
    end

    context "with other text" do
      it "leaves normal text unchanged" do
        result = Reminders::Sanitizer.call("hello world")
        expect(result).to eq("hello world")
      end

      it "leaves @username unchanged" do
        result = Reminders::Sanitizer.call("@john please help")
        expect(result).to eq("@john please help")
      end

      it "leaves a lone @ unchanged" do
        result = Reminders::Sanitizer.call("@ symbol here")
        expect(result).to eq("@ symbol here")
      end

      it "leaves other mentions intact" do
        result = Reminders::Sanitizer.call("@alice @bob @charlie")
        expect(result).to eq("@alice @bob @charlie")
      end
    end

    context "with nil input" do
      it "converts nil to empty string" do
        result = Reminders::Sanitizer.call(nil)
        expect(result).to eq("")
      end
    end

    context "with edge cases" do
      it "handles empty string" do
        result = Reminders::Sanitizer.call("")
        expect(result).to eq("")
      end

      it "handles @everyone with punctuation" do
        result = Reminders::Sanitizer.call("@everyone!")
        expect(result).not_to include("@everyone")
        expect(result).to include("!")
      end
    end
  end
end
