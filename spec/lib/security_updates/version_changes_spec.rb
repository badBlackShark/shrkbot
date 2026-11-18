# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecurityUpdates::VersionChanges do
  def lockfile(rack:, rake:)
    <<~LOCK
      GEM
        remote: https://rubygems.org/
        specs:
          nokogiri (1.18.0-x86_64-linux)
          nokogiri (1.18.0-arm64-darwin)
          rack (#{rack})
          rake (#{rake})

      PLATFORMS
        ruby

      DEPENDENCIES
        rack
        rake

      BUNDLED WITH
         4.1.0
    LOCK
  end

  describe ".gems" do
    subject(:changes) { described_class.gems(before, after) }

    let(:before) { lockfile(rack: "3.0.0", rake: "13.0.0") }
    let(:after) { lockfile(rack: "3.1.0", rake: "13.0.0").gsub("1.18.0", "1.19.0") }

    it "lists each changed gem once, even with platform variants" do
      expect(changes).to contain_exactly("`rack` 3.0.0 → 3.1.0", "`nokogiri` 1.18.0 → 1.19.0")
    end

    context "when the update adds and drops a dependency" do
      let(:after) { lockfile(rack: "3.1.0", rake: "13.0.0").sub("rake (13.0.0)", "rack-session (2.1.0)") }

      it "lists the added and the removed gem" do
        expect(changes).to include("`rack-session` (none) → 2.1.0", "`rake` 13.0.0 → (removed)")
      end
    end

    context "when nothing changed" do
      let(:after) { before }

      it { is_expected.to be_empty }
    end
  end

  describe ".pins" do
    subject(:changes) { described_class.pins(before, after) }

    let(:before) do
      <<~RUBY
        pin "tom-select" # @2.6.1
        pin "@orchidjs/sifter", to: "@orchidjs--sifter.js" # @1.1.0
        pin "application"
        pin "local" # @1.0.0
      RUBY
    end
    let(:after) do
      <<~RUBY
        pin "tom-select" # @2.6.2
        pin "@orchidjs/sifter", to: "@orchidjs--sifter.js" # @1.2.0
        pin "application"
        pin "local" # @1.0.0
      RUBY
    end

    it "lists version changes for both pin line shapes and ignores unversioned pins" do
      expect(changes).to contain_exactly("`tom-select` 2.6.1 → 2.6.2", "`@orchidjs/sifter` 1.1.0 → 1.2.0")
    end
  end
end
