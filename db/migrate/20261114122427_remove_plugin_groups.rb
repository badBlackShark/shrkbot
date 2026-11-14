# frozen_string_literal: true

class RemovePluginGroups < ActiveRecord::Migration[8.1]
  GROUPS = {"moderation" => %w[spam_protection image_scanning], "integrations" => %w[steam twitch]}.freeze

  def up
    safety_assured do
      GROUPS.each { |group, children| disable_children_of_disabled(group, children) }
      execute "DELETE FROM plugin_activations WHERE plugin_id IN (SELECT id FROM plugins WHERE key IN ('moderation', 'integrations'))"
      execute "DELETE FROM plugins WHERE key IN ('moderation', 'integrations')"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def disable_children_of_disabled(group, children)
    execute <<~SQL
      UPDATE plugin_activations AS child SET enabled = false, updated_at = CURRENT_TIMESTAMP
      FROM plugins AS child_plugin
      WHERE child.plugin_id = child_plugin.id
        AND child_plugin.key IN (#{children.map { |key| connection.quote(key) }.join(", ")})
        AND child.enabled
        AND NOT EXISTS (
          SELECT 1 FROM plugin_activations AS parent
          JOIN plugins AS parent_plugin ON parent_plugin.id = parent.plugin_id
          WHERE parent.server_configuration_id = child.server_configuration_id
            AND parent_plugin.key = #{connection.quote(group)}
            AND parent.enabled
        )
    SQL
  end
end
