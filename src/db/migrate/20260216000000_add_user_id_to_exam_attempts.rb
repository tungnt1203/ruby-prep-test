# frozen_string_literal: true

class AddUserIdToExamAttempts < ActiveRecord::Migration[8.1]
  def change
    add_reference :exam_attempts, :user, foreign_key: true, null: true
    add_index :exam_attempts, [ :user_id, :exam_session_id, :exam_room_id ], name: "index_exam_attempts_on_user_session_room"
  end
end
