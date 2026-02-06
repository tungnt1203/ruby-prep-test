# frozen_string_literal: true

class AddExamRoomToExamAttempts < ActiveRecord::Migration[8.0]
  def change
    add_reference :exam_attempts, :exam_room, null: true, foreign_key: true
  end
end
