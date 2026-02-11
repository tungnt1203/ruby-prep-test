# frozen_string_literal: true

class AddUniqueIndexToSolidCableMessagesId < ActiveRecord::Migration[8.1]
  def change
    add_index :solid_cable_messages, :id, unique: true, name: "index_solid_cable_messages_on_id"
  end
end
