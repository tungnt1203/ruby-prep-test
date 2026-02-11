# frozen_string_literal: true

namespace :db do
  desc "Load exam_ruby_silver JSON files into question bank"
  task seed_question_bank: :environment do
    dir = Rails.root.join("exam_ruby_silver")
    raise "Directory exam_ruby_silver not found" unless dir.exist?

    json_files = Dir.glob(dir.join("*.json")).sort
    raise "No JSON files found in exam_ruby_silver" if json_files.empty?

    BankQuestionChoice.delete_all
    BankQuestion.delete_all
    QuestionTopic.delete_all

    total_questions = 0

    json_files.each do |path|
      data = JSON.parse(File.read(path))
      topic_name = data["topic"].presence || File.basename(path, ".json").titleize
      topic_key = File.basename(path, ".json")

      topic = QuestionTopic.create!(key: topic_key, name: topic_name)

      questions_data = data["questions"] || []
      questions_data.each do |q|
        question_type = (q["type"].to_s == "multiple") ? "multiple" : "single"
        answer_keys = Array.wrap(q["answer"]).map { |a| a.to_s.upcase }

        bank_q = topic.bank_questions.create!(
          question_type: question_type,
          body: q["question"].to_s,
          explanation: q["explanation"].to_s.presence
        )

        options = q["options"] || {}
        options.each do |key, label|
          key_up = key.to_s.upcase
          bank_q.bank_question_choices.create!(
            choice_key: key_up,
            label: label.to_s,
            is_correct: answer_keys.include?(key_up)
          )
        end

        total_questions += 1
      end
    end

    puts "Loaded #{total_questions} questions from #{json_files.size} topics."
  end
end
