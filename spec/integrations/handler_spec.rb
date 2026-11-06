# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Handler do
  subject(:declare) { handler.handles(Integrations::Steam::PatchNotesPublished, Integrations::Steam::ArticlePublished) }

  let(:handler) { Class.new(ApplicationJob) { include Integrations::Handler } }

  before do
    allow(Integrations::Bus).to receive(:subscriptions).and_return({})
  end

  it "subscribes the job to every event class it handles" do
    declare

    expect(Integrations::Bus.subscriptions).to eq(handler => [Integrations::Steam::PatchNotesPublished, Integrations::Steam::ArticlePublished])
  end
end
