# frozen_string_literal: true

class Components::Base < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::Translate

  private

  def column_default(settings_class, column)
    settings_class.column_defaults.fetch(column)
  end
end
