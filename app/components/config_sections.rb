# frozen_string_literal: true

class Components::ConfigSections < Components::Base
  def initialize(key:, enable_error: nil, data: {})
    @key = key
    @enable_error = enable_error
    @data = data
  end

  def view_template(&block)
    div(id: "#{@key}-config", class: "flex flex-col gap-5", data: @data) do
      enable_error_callout
      yield
    end
  end

  private

  def enable_error_callout
    return unless @enable_error

    render Components::Callout.new(variant: :danger) { @enable_error }
  end
end
