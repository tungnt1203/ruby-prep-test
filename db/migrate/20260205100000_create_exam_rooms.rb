# frozen_string_literal: true

class CreateExamRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :exam_rooms do |t|
      t.references :exam_session, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.integer :duration_minutes, null: true, comment: "Time limit in minutes; null = no limit"
      t.string :room_code, null: false, index: { unique: true }
      t.string :name, null: true

      t.timestamps
    end
  end
end
