# frozen_string_literal: true

class AddRoomSettingsToExamRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :exam_rooms, :instructions, :text
    add_column :exam_rooms, :require_display_name, :boolean, default: true, null: false
    add_column :exam_rooms, :require_candidate_identifier, :boolean, default: false, null: false
  end
end
