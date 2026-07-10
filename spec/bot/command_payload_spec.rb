# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe CommandPayload do
  def build_registration(overrides = {})
    BaseCommand::Registration.new(
      overrides.fetch(:name, :test),
      overrides.fetch(:description, "A test command"),
      overrides.fetch(:permissions, []),
      overrides.fetch(:owner_only, false),
      overrides.fetch(:context, :guild),
      overrides.fetch(:type, :chat_input),
      overrides.fetch(:options_block, nil),
      overrides.fetch(:plugin, nil)
    )
  end

  describe "#to_h" do
    context "with a chat_input command with options and permissions" do
      subject(:payload) { described_class.new(registration).to_h }

      let(:registration) do
        build_registration(
          name: :greet,
          description: "Say hello",
          permissions: [:manage_messages],
          options_block: proc { |opts| opts.string("target", "Who to greet", required: true) }
        )
      end

      it "includes name and description" do
        expect(payload[:name]).to eq(:greet)
        expect(payload[:description]).to eq("Say hello")
      end

      it "maps type to integer 1 for chat_input" do
        expect(payload[:type]).to eq(1)
      end

      it "includes default_member_permissions as a string of bits" do
        bits = Discordrb::Permissions.bits([:manage_messages]).to_s
        expect(payload[:default_member_permissions]).to eq(bits)
      end

      it "includes options array" do
        expect(payload[:options]).to be_an(Array)
        expect(payload[:options]).not_to be_empty
      end

      it "omits contexts for a guild command" do
        expect(payload).not_to have_key(:contexts)
      end
    end

    context "with a message context-menu command" do
      subject(:payload) { described_class.new(registration).to_h }

      let(:registration) do
        build_registration(
          name: "Report as scam",
          description: "",
          type: :message,
          options_block: nil
        )
      end

      it "maps type to integer 3 for message" do
        expect(payload[:type]).to eq(3)
      end

      it "has an empty description" do
        expect(payload[:description]).to eq("")
      end

      it "omits options key when no options_block" do
        expect(payload).not_to have_key(:options)
      end
    end

    context "with a global command" do
      subject(:payload) { described_class.new(registration).to_h }

      let(:registration) do
        build_registration(
          context: :global,
          name: :info,
          description: "Bot info"
        )
      end

      it "includes contexts as integers" do
        expect(payload[:contexts]).to be_an(Array)
        expect(payload[:contexts]).to all(be_an(Integer))
      end
    end

    context "with a guild command" do
      subject(:payload) { described_class.new(registration).to_h }

      let(:registration) do
        build_registration(context: :guild)
      end

      it "omits contexts key" do
        expect(payload).not_to have_key(:contexts)
      end
    end

    context "with no permissions" do
      subject(:payload) { described_class.new(registration).to_h }

      let(:registration) do
        build_registration(permissions: [])
      end

      it "omits default_member_permissions key" do
        expect(payload).not_to have_key(:default_member_permissions)
      end
    end
  end
end
