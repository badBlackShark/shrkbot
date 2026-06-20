require "rails_helper"

RSpec.describe ActivityLog do
  subject(:record) { described_class.record(server_config, event, bot:, **options) }

  let(:server_config) { create(:server_configuration) }
  let(:event) { :role_gained }
  let(:options) { {actor: "<@42>", roles: ["Gamer"]} }

  let(:channel) { double("channel", send_message: nil) }
  let(:bot) { double("bot") }

  before do
    create(
      :logging_setting,
      server_configuration: server_config,
      channel_id: 555,
      enabled_actions: {"roles.assignment" => true}
    )
    logging = create(:plugin, key: "logging", name: "Logging")
    create(:plugin_activation, server_configuration: server_config, plugin: logging, enabled: true)
    allow(bot).to receive(:channel).with(555).and_return(channel)
  end

  it "writes the rendered line to the logging channel" do
    expect(channel).to receive(:send_message).with("<@42> gained Gamer.")
    record
  end

  context "with several roles" do
    let(:options) { {actor: "<@42>", roles: ["Gamer", "Artist"]} }

    it "joins the list into a sentence" do
      expect(channel).to receive(:send_message).with("<@42> gained Gamer and Artist.")
      record
    end
  end

  context "for a gained-and-lost change" do
    let(:event) { :roles_changed }
    let(:options) { {actor: "<@42>", gained: ["Gamer"], lost: ["Artist", "News"]} }

    it "renders both sides" do
      expect(channel).to receive(:send_message).with("<@42> gained Gamer and lost Artist and News.")
      record
    end
  end

  context "when the logging plugin is disabled" do
    before { PluginActivation.update_all(enabled: false) }

    it "writes nothing" do
      expect(channel).not_to receive(:send_message)
      record
    end
  end

  context "when the action is toggled off" do
    before { server_config.logging_setting.update!(enabled_actions: {}) }

    it "writes nothing" do
      expect(channel).not_to receive(:send_message)
      record
    end
  end

  context "when no logging channel is set" do
    before { server_config.logging_setting.update!(channel_id: nil) }

    it "writes nothing" do
      expect(channel).not_to receive(:send_message)
      record
    end
  end

  context "when the logging channel no longer exists" do
    before { allow(bot).to receive(:channel).with(555).and_return(nil) }

    it "writes nothing and doesn't raise" do
      expect { record }.not_to raise_error
    end
  end

  context "when the channel send fails" do
    before { allow(channel).to receive(:send_message).and_raise("403 missing access") }

    it "swallows the error so the user's action is unaffected" do
      expect { record }.not_to raise_error
    end
  end

  context "for an unregistered event" do
    let(:event) { :not_a_real_event }

    it "raises so the wiring mistake surfaces" do
      expect { record }.to raise_error(KeyError)
    end
  end
end
