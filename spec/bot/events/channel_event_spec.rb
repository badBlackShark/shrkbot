# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ChannelEvent do
  subject(:handle) { klass.new(event).handle }

  let(:server) { double("server", id: 1) }
  let(:event) { double("event", server:) }
  let(:applied) { [] }
  let(:klass) do
    applications = applied
    Class.new(described_class) do
      define_method(:apply) { applications << server_configuration }
    end
  end

  context "for a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    it "applies against the resolved configuration" do
      handle

      expect(applied).to eq([config])
    end

    context "without an #apply implementation" do
      let(:klass) { Class.new(described_class) }

      it "is abstract" do
        expect { handle }.to raise_error(AbstractMethodError)
      end
    end
  end

  context "for a non-guild channel (no server)" do
    let(:server) { nil }

    it "does nothing" do
      handle

      expect(applied).to be_empty
    end
  end

  context "for a server with no configuration" do
    it "does nothing" do
      handle

      expect(applied).to be_empty
    end
  end
end
