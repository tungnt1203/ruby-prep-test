# frozen_string_literal: true

class AddDisplayNameToExamAttempts < ActiveRecord::Migration[8.0]
  def change
    add_column :exam_attempts, :display_name, :string
  end
end
