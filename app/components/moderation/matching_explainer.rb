# frozen_string_literal: true

class Components::Moderation::MatchingExplainer < Components::Base
  def view_template
    render Components::Moderation::Explainer.new(
      id: "matching",
      title: t(".title"),
      rows: [t(".row_normalize"), t(".row_lookalike"), t(".row_spam"), t(".row_keywords")]
    )
  end
end
