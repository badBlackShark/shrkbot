require "rails_helper"

RSpec.describe Components::Wordmark do
  subject(:html) { described_class.new.call }

  it "renders 'shrk' in the teal accent and 'bot' in the copper accent" do
    expect(html).to include('class="text-accent">shrk')
    expect(html).to include('class="text-accent-2-text">bot')
  end
end
