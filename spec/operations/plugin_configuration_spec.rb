# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::PluginConfiguration do
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
