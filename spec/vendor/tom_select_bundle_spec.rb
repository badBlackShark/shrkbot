# frozen_string_literal: true

require "rails_helper"

# bin/importmap's downloader fetches only a package's entry file, not the
# relative modules that entry imports — which silently left every styled
# <select> falling back to the native OS dropdown. Guard that the vendored
# bundles are self-contained, i.e. import only bare (importmap-pinned)
# specifiers, never a relative path or CDN URL.
RSpec.describe "Vendored Tom Select bundle" do
  bundles = %w[tom-select @orchidjs--sifter @orchidjs--unicode-variants]
    .map { |name| Rails.root.join("vendor/javascript/#{name}.js") }

  bundles.each do |path|
    context path.basename.to_s do
      subject(:source) { path.read }

      it "imports nothing by relative path or CDN URL" do
        expect(source).not_to match(%r{(?:from|import)\s*["'](?:\./|/npm/)})
      end
    end
  end

  it "exposes Tom Select as a default export" do
    expect(Rails.root.join("vendor/javascript/tom-select.js").read).to include("as default}")
  end

  it "bundles the dropdown_input plugin the channel picker relies on for its search field" do
    expect(Rails.root.join("vendor/javascript/tom-select.js").read).to include("dropdown_input")
  end
end
