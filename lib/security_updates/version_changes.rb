# frozen_string_literal: true

require "bundler"

module SecurityUpdates
  class VersionChanges
    PIN_LINE = /\A\s*pin\s+"([^"]+)".*#\s*@(\S+)/

    def self.gems(before_lockfile, after_lockfile)
      changes(gem_versions(before_lockfile), gem_versions(after_lockfile))
    end

    def self.pins(before_importmap, after_importmap)
      changes(pin_versions(before_importmap), pin_versions(after_importmap))
    end

    def self.gem_versions(lockfile)
      Bundler::LockfileParser.new(lockfile).specs.to_h { |spec| [spec.name, spec.version.to_s] }
    end

    def self.pin_versions(importmap)
      importmap.lines.filter_map { |line| line.match(PIN_LINE)&.captures }.to_h
    end

    def self.changes(before, after)
      after.filter_map do |name, version|
        "`#{name}` #{before[name]} → #{version}" if before.key?(name) && before[name] != version
      end
    end

    private_class_method :gem_versions, :pin_versions, :changes
  end
end
