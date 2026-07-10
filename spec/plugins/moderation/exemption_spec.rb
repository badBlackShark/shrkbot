# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Exemption do
  let(:owner_id) { 111 }
  let(:staff_role_id) { 222 }
  let(:owner) { double("owner", id: owner_id) }
  let(:server) { double("server", owner:) }

  describe ".exempt?" do
    subject(:result) { described_class.exempt?(member:, server:, staff_role_id:) }

    context "when the member is the server owner" do
      let(:member) { double("member", id: owner_id, roles: []) }

      it "is true" do
        expect(result).to be(true)
      end
    end

    context "when the member holds the staff role" do
      let(:staff_role) { double("role", id: staff_role_id) }
      let(:member) { double("member", id: 999, roles: [staff_role]) }

      it "is true" do
        expect(result).to be(true)
      end
    end

    context "when staff_role_id is nil and the member is not the owner" do
      let(:staff_role_id) { nil }
      let(:member) { double("member", id: 999, roles: []) }

      it "is false" do
        expect(result).to be(false)
      end
    end

    context "when the member has other roles but not the staff role" do
      let(:other_role) { double("role", id: 333) }
      let(:member) { double("member", id: 999, roles: [other_role]) }

      it "is false" do
        expect(result).to be(false)
      end
    end
  end
end
