# frozen_string_literal: true

RSpec.shared_context "component view context" do
  let(:view_context) do
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create({"HTTP_HOST" => "localhost"})
    controller.view_context
  end
end
