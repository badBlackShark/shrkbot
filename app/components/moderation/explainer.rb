# frozen_string_literal: true

class Components::Moderation::Explainer < Components::Base
  def initialize(title:, rows:, ordered: false, id: nil)
    @title = title
    @rows = rows
    @ordered = ordered
    @id = id
  end

  def view_template
    div(id: @id, class: "overflow-hidden rounded-card border border-border-default bg-surface-card shadow-sm") do
      details(data: {controller: "disclosure"}) do
        summary(
          class: "flex cursor-pointer list-none select-none items-center gap-3 bg-surface-sunken border-b border-border-subtle px-5 py-3.5 [&::-webkit-details-marker]:hidden",
          data: {action: "click->disclosure#toggle"}
        ) do
          render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 flex-none text-text-muted")
          span(class: "flex-1 text-sm font-semibold") { @title }
        end
        div(class: "px-5 py-4") { list }
      end
    end
  end

  private

  def list
    if @ordered
      ol(class: "list-decimal list-outside space-y-2.5 pl-5 marker:text-text-muted") { rows }
    else
      ul(class: "list-['-'] list-outside space-y-2.5 pl-4 marker:text-text-muted") { rows }
    end
  end

  def rows
    @rows.each { |text| li(class: "pl-1 text-sm text-text-secondary") { text } }
  end
end
