# frozen_string_literal: true

class Components::SettingRow < Components::Base
  ALIGNMENTS = {center: "items-center", title: "items-start"}.freeze
  TEXT = {center: "flex-1", title: "flex-1 py-0.5"}.freeze

  def initialize(label:, help: nil, align: :center)
    @label = label
    @help = help
    @align = align
  end

  def view_template
    div(class: "flex #{ALIGNMENTS.fetch(@align)} gap-4") do
      div(class: TEXT.fetch(@align)) do
        p(class: "text-sm font-semibold") { @label }
        render(Components::Description.new { @help }) if @help
      end
      yield
    end
  end
end
