# frozen_string_literal: true

class AddQuestionBank < ActiveRecord::Migration[8.0]
  def change
    create_table :question_topics do |t|
      t.string :key, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :question_topics, :key, unique: true

    create_table :bank_questions do |t|
      t.references :question_topic, null: false, foreign_key: true
      t.string :question_type, null: false
      t.text :body, null: false
      t.text :explanation

      t.timestamps
    end

    create_table :bank_question_choices do |t|
      t.references :bank_question, null: false, foreign_key: true
      t.string :choice_key, null: false
      t.text :label, null: false
      t.boolean :is_correct, default: false, null: false

      t.timestamps
    end
    add_index :bank_question_choices, [ :bank_question_id, :choice_key ], unique: true

    add_column :questions, :topic_key, :string
    add_column :questions, :topic_name, :string
  end
end
