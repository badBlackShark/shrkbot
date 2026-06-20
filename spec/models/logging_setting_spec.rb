require "rails_helper"

RSpec.describe LoggingSetting do
  subject(:setting) { build(:logging_setting, enabled_actions: actions) }

  describe "#action_enabled?" do
    context "when the action is toggled on" do
      let(:actions) { {"roles.assignment" => true} }

      it { expect(setting.action_enabled?("roles.assignment")).to be(true) }

      it "accepts a symbol" do
        expect(setting.action_enabled?(:"roles.assignment")).to be(true)
      end
    end

    context "when the action is absent" do
      let(:actions) { {} }

      it { expect(setting.action_enabled?("roles.assignment")).to be(false) }
    end

    context "when the action is explicitly off" do
      let(:actions) { {"roles.assignment" => false} }

      it { expect(setting.action_enabled?("roles.assignment")).to be(false) }
    end
  end
end
