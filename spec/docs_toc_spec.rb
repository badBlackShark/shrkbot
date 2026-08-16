# frozen_string_literal: true

require "rails_helper"

RSpec.describe "docs/README.md" do
  let(:docs_root) { Rails.root.join("docs") }
  let(:toc) { docs_root.join("README.md") }
  let(:excluded) { %r{\Adocs/site/} }
  let(:pages) do
    Pathname.glob(docs_root.join("**/*.md"))
      .reject { |path| path == toc || path.relative_path_from(Rails.root).to_s.match?(excluded) }
  end

  def links_in(page)
    page.read.scan(/\[[^\]]*\]\(([^)]+)\)/).flatten
      .reject { |target| target.match?(%r{\A(?:[a-z][a-z0-9+.-]*:|#)}i) }
      .map { |target| page.dirname.join(target.split("#").first).cleanpath }
  end

  describe "the table of contents" do
    subject(:unlisted) { pages - links_in(toc) }

    it "links every doc, so a new page can't be invisible to whoever needs it" do
      expect(unlisted).to be_empty
    end
  end

  describe "every relative link under docs/" do
    subject(:broken) do
      (pages + [toc]).flat_map do |page|
        links_in(page).reject(&:exist?).map { |target| "#{page} -> #{target}" }
      end
    end

    it "points at a file that exists" do
      expect(broken).to be_empty
    end
  end
end
