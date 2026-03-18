class AddDeactivationFieldsToWebhooksOutgoingEndpoints < ActiveRecord::Migration[8.0]
  def change
    add_column :webhooks_outgoing_endpoints, :deactivation_limit_reached_at, :datetime
    add_column :webhooks_outgoing_endpoints, :deactivated_at, :datetime
    add_column :webhooks_outgoing_endpoints, :consecutive_failed_deliveries, :integer, default: 0, null: false
  end
end
