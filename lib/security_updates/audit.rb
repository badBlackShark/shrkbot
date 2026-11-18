# frozen_string_literal: true

module SecurityUpdates
  class Audit
    INSECURE_SOURCE_ID = "insecure-source"

    def self.gems(report)
      report.fetch("results").map do |result|
        if result.fetch("type") == "insecure_source"
          insecure_source(result)
        else
          unpatched_gem(result)
        end
      end
    end

    def self.pins(vulnerable_packages)
      vulnerable_packages.map do |package|
        Advisory.new(
          package: package.name,
          version: package.vulnerable_versions,
          id: package.severity,
          title: package.vulnerability,
          url: nil,
          fixed_in: ["latest"]
        )
      end
    end

    def self.unpatched_gem(result)
      advisory = result.fetch("advisory")
      Advisory.new(
        package: result.dig("gem", "name"),
        version: result.dig("gem", "version"),
        id: advisory.fetch("id"),
        title: advisory.fetch("title"),
        url: advisory.fetch("url"),
        fixed_in: advisory.fetch("patched_versions")
      )
    end

    def self.insecure_source(result)
      Advisory.new(
        package: result.fetch("source"),
        version: nil,
        id: INSECURE_SOURCE_ID,
        title: "Gem source uses an insecure protocol",
        url: nil,
        fixed_in: []
      )
    end

    private_class_method :unpatched_gem, :insecure_source
  end
end
