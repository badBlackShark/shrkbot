# frozen_string_literal: true

require "rails_helper"

RSpec.describe Views::Servers::PluginConfigShow do
  subject(:view) do
    described_class.new(
      server_configuration: build(:server_configuration),
      user: build(:user),
      enabled: true
    )
  end

  [:plugin_key, :icon, :url, :form].each do |method|
    describe "##{method}" do
      it "is abstract" do
        expect { view.send(method) }.to raise_error(AbstractMethodError)
      end
    end
  end
end
