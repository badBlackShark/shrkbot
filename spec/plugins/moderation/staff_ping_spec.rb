# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::StaffPing do
  describe ".prefix" do
    subject(:prefix) { described_class.prefix(staff_role_id, **kwargs) }

    let(:kwargs) { {} }

    context "with a staff role id" do
      let(:staff_role_id) { 123 }

      it "renders a role mention with a colon and trailing space" do
        expect(prefix).to eq("<@&123>: ")
      end
    end

    context "with ping: false" do
      let(:staff_role_id) { 123 }
      let(:kwargs) { {ping: false} }

      it "returns an empty string" do
        expect(prefix).to eq("")
      end
    end
  end

  describe ".allowed_roles" do
    subject(:allowed_roles) { described_class.allowed_roles(staff_role_id, **kwargs) }

    let(:kwargs) { {} }

    context "with a staff role id" do
      let(:staff_role_id) { 123 }

      it "returns the id wrapped in an array" do
        expect(allowed_roles).to eq([123])
      end
    end

    context "with ping: false" do
      let(:staff_role_id) { 123 }
      let(:kwargs) { {ping: false} }

      it "returns an empty array" do
        expect(allowed_roles).to eq([])
      end
    end

    context "with nil id and ping: true" do
      let(:staff_role_id) { nil }

      it "returns an empty array" do
        expect(allowed_roles).to eq([])
      end
    end
  end
end
