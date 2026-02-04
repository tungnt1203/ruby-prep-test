# frozen_string_literal: true

# Each exam attempt represents one submission instance (no overwrites).
class CreateExamAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :exam_attempts do |t|
      t.references :exam_session, null: false, foreign_key: true
      t.string :attempt_token, null: false, index: { unique: true }
      t.text :submissions

      t.timestamps
    end
  end
end
