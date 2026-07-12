# frozen_string_literal: true

class ReleaseInfo
  REPO_URL = "https://github.com/badBlackShark/shrkbot"
  CHANGELOG = Rails.root.join("CHANGELOG.md")
  ENTRY = /^## \[(\d+\.\d+\.\d+)\] - (\d{4}-\d{2}-\d{2})/

  def self.current
    @current ||= CHANGELOG.exist? ? from_changelog(CHANGELOG.read) : nil
  end

  def self.from_changelog(text)
    match = text.match(ENTRY)
    return unless match

    new(number: match[1], released_on: Date.parse(match[2]))
  end
  private_class_method :from_changelog

  attr_reader :number, :released_on

  def initialize(number:, released_on:)
    @number = number
    @released_on = released_on
  end

  def release_url
    "#{REPO_URL}/releases/tag/#{number}"
  end
end
