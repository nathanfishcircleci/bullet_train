class AddDeactivatedAtToWebhooksOutgoingEndpoints < ActiveRecord::Migration[8.0]
  def change
    add_column :webhooks_outgoing_endpoints, :deactivated_at, :datetime
  end
end
