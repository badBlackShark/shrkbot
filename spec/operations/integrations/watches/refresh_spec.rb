# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Watches::Refresh do
  subject(:result) { described_class.call(watches: [watch, untouched], targets:) }

  let!(:watch) { create(:integration_watch, external_id: "1145360", name: "Old", image_url: "https://example.com/old.jpg") }
  let!(:untouched) { create(:integration_watch, external_id: "440", name: "Team Fortress 2", image_url: "https://example.com/tf2.jpg") }
  let(:targets) { [Integrations::Target.new(external_id: "1145360", name: "Hades", image_url: "https://example.com/new.jpg")] }

  it "writes the new name and image" do
    result

    expect(watch.reload).to have_attributes(name: "Hades", image_url: "https://example.com/new.jpg")
  end

  it "leaves a watch without a target alone" do
    expect { result }.not_to change { untouched.reload.attributes }
  end

  context "when nothing changed" do
    let(:targets) { [Integrations::Target.new(external_id: "1145360", name: "Old", image_url: "https://example.com/old.jpg")] }

    it "does not touch updated_at" do
      expect { result }.not_to change { watch.reload.updated_at }
    end
  end

  context "when the target has no image" do
    let(:targets) { [Integrations::Target.new(external_id: "1145360", name: "Hades", image_url: nil)] }

    it "clears the image" do
      result

      expect(watch.reload.image_url).to be_nil
    end
  end
end
