# frozen_string_literal: true

module SecurityUpdates
  class Report
    INTRO = "The nightly audit found these advisories."

    def initialize(found:, remaining:, changes:)
      remaining_keys = remaining.map(&:key)
      @fixed = found.reject { |advisory| remaining_keys.include?(advisory.key) }
      @remaining = remaining
      @changes = changes
    end

    def to_markdown
      lines = [INTRO, ""]
      lines += ["## Fixed", *@fixed.map { |advisory| advisory_line(advisory) }, ""] if @fixed.any?
      lines += ["## Version changes", *@changes.map { |change| "- #{change}" }, ""] if @changes.any?
      lines += unresolved_section
      lines.join("\n")
    end

    def unresolved?
      @remaining.any?
    end

    private

    def unresolved_section
      return [] if @remaining.empty?

      ["## Unresolved", "No update fixes these, so they need a manual change.", *@remaining.map { |advisory| advisory_line(advisory) }]
    end

    def advisory_line(advisory)
      reference = advisory.url ? "[#{advisory.id}](#{advisory.url})" : advisory.id
      version = " #{advisory.version}" if advisory.version
      "- `#{advisory.package}`#{version}: #{reference} #{advisory.title} (#{fixed_in(advisory)})"
    end

    def fixed_in(advisory)
      return "no fixed version yet" if advisory.fixed_in.empty?

      "fixed in #{advisory.fixed_in.join(", ")}"
    end
  end
end
