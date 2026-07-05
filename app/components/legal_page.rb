# frozen_string_literal: true

class Components::LegalPage < Components::Base
  def initialize(title:, updated:)
    @title = title
    @updated = updated
  end

  def view_template(&block)
    render Components::PublicShell.new do
      article(class: "mx-auto max-w-2xl px-6 py-16") do
        h1(class: "mb-2 font-display text-3xl font-bold tracking-tight") { @title }
        p(class: "mb-10 text-sm text-text-muted") { @updated }
        yield
      end
    end
  end
end
