require "rails_helper"

RSpec.describe LoggableEventCatalog do
  it "enumerates the events the bot emits, keyed <plugin>.<event>" do
    expect(described_class.all.map(&:key)).to contain_exactly("roles.role_gained", "roles.role_lost")
  end

  it "groups events by plugin for the config matrix" do
    grouped = described_class.grouped_by_plugin
    expect(grouped.keys).to eq([:roles])
    expect(grouped[:roles].map(&:event)).to eq([:role_gained, :role_lost])
  end

  it "has a log-line translation for every catalogued event" do
    described_class.all.each do |definition|
      expect(I18n.exists?("activity_log.#{definition.key}", :en)).to be(true)
    end
  end
end
