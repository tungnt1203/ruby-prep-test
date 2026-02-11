# frozen_string_literal: true

class CreateSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    unless table_exists?(:solid_cable_messages)
      create_table :solid_cable_messages, force: :cascade do |t|
        t.binary :channel, limit: 1024, null: false
        t.binary :payload, limit: 536870912, null: false
        t.datetime :created_at, null: false
        t.integer :channel_hash, limit: 8, null: false
      end
      add_index :solid_cable_messages, :channel, name: "index_solid_cable_messages_on_channel"
      add_index :solid_cable_messages, :channel_hash, name: "index_solid_cable_messages_on_channel_hash"
      add_index :solid_cable_messages, :created_at, name: "index_solid_cable_messages_on_created_at"
      add_index :solid_cable_messages, :id, unique: true, name: "index_solid_cable_messages_on_id"
    else
      # Bảng đã có (từ cable_schema.rb), chỉ thêm unique index trên id nếu chưa có
      unless index_exists?(:solid_cable_messages, :id, name: "index_solid_cable_messages_on_id")
        add_index :solid_cable_messages, :id, unique: true, name: "index_solid_cable_messages_on_id"
      end
    end
  end
end
