# frozen_string_literal: true

class CreateQuestionChoices < ActiveRecord::Migration[8.0]
  def change
    create_table :question_choices do |t|
      t.references :question, null: false, foreign_key: true
      t.integer :external_choice_id, null: false
      t.text :label, null: false

      t.timestamps
    end

    add_index :question_choices, [:question_id, :external_choice_id], unique: true
  end
end
