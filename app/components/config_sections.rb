# frozen_string_literal: true

class Components::ConfigSections < Components::Base
  def initialize(key:, save_error: nil, data: {})
    @key = key
    @save_error = save_error
    @data = data
  end

  def view_template
    div(id: "#{@key}-config", class: "flex flex-col gap-5", data: @data) do
      render Components::SaveErrorCallout.new(key: @key, message: @save_error)
      yield
    end
  end
end
