# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Interaction::StaffGate do
  subject(:result) { described_class.allows?(member, staff_role_id) }

  let(:staff_role_id) { 999 }

  context "when member is nil" do
    let(:member) { nil }

    it "denies" do
      is_expected.to be(false)
    end
  end

  context "when member has the staff role" do
    let(:member) { double("member", roles: [double("role", id: staff_role_id)], permission?: false) }

    it "allows" do
      is_expected.to be(true)
    end
  end

  context "when member has the manage_messages permission but not the staff role" do
    let(:member) { double("member", roles: [], permission?: true) }

    it "allows" do
      is_expected.to be(true)
    end
  end

  context "when member has neither the staff role nor manage_messages" do
    let(:member) { double("member", roles: [], permission?: false) }

    it "denies" do
      is_expected.to be(false)
    end
  end

  context "when staff_role_id is nil and member has manage_messages" do
    let(:staff_role_id) { nil }
    let(:member) { double("member", roles: [], permission?: true) }

    it "allows via permission" do
      is_expected.to be(true)
    end
  end
end
