# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::PluginConfiguration do
  context "without plugin_key" do
    subject(:operation) do
      Class.new(Ops::ApplicationOperation) do
        include Ops::PluginConfiguration

        def call
          plugin_key
        end
      end
    end

    it "requires the including operation to define plugin_key" do
      expect { operation.call }.to raise_error(AbstractMethodError)
    end
  end

  context "when a later write is invalid inside a transactional operation" do
    subject(:result) { operation.call(server_configuration: config, enabled: "1") }

    let(:operation) do
      Class.new(Ops::ApplicationOperation) do
        include Ops::PluginConfiguration

        receives :server_configuration, :enabled

        def call
          settings = server_configuration.welcome_settings
          settings.channel_id = 111
          save_with_activation(settings) do
            settings.errors.add(:base, "Broken later write")
            raise ActiveRecord::RecordInvalid, settings
          end
        end

        private

        def plugin_key
          :welcomes
        end
      end
    end

    let(:config) { create(:server_configuration) }

    before do
      create(:plugin, key: "welcomes", name: "Welcomes")
      config.create_welcome_settings!
    end

    it "fails with the record's messages" do
      expect(result.errors).to eq(["Broken later write"])
    end

    it "rolls back the activation and the settings it saved before the failure" do
      result
      expect(config.reload.enabled_plugin_keys).not_to include(:welcomes)
      expect(config.welcome_settings.reload.channel_id).to be_nil
    end
  end
end
