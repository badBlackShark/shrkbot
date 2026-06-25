# frozen_string_literal: true

module Commands
  class Announce < BaseCommand
    command_name :announce
    description "Broadcast a message to the owner of every server shrkbot is in. Bot owner only."
    owner_only
    register_in :global

    MODAL_ID = "announce:compose"
    INPUT_ID = "announce:content"

    def execute
      event.show_modal(title: "Owner announcement", custom_id: MODAL_ID) do |modal|
        modal.label(label: "Announcement", description: "DM'd to every unique server owner.") do |row|
          row.text_input(
            style: :paragraph,
            custom_id: INPUT_ID,
            required: true,
            max_length: 2000,
            placeholder: "Write your announcement…"
          )
        end
      end
    end
  end
end
