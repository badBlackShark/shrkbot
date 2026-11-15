# frozen_string_literal: true

module PrerequisiteStepLinks
  def step_links(html)
    Nokogiri::HTML(html).css("a").to_h { |link| [link.text.strip, link["href"]] }
  end
end

RSpec.configure do |config|
  config.include PrerequisiteStepLinks, type: :request
end
