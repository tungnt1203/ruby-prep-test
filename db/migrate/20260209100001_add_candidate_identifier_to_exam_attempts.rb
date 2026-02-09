# frozen_string_literal: true

class AddCandidateIdentifierToExamAttempts < ActiveRecord::Migration[8.1]
  def change
    add_column :exam_attempts, :candidate_identifier, :string
  end
end
