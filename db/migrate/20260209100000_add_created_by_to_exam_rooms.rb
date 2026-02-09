# frozen_string_literal: true

class AddCreatedByToExamRooms < ActiveRecord::Migration[8.1]
  def change
    add_reference :exam_rooms, :created_by, foreign_key: { to_table: :users }, index: true
  end
end
