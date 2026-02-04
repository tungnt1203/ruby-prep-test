# frozen_string_literal: true

module Gemini
  # For a given Question, fetches the AI answer key + explanation and persists it.
  class FetchAndSaveCorrectAnswers
    def initialize(question, api_key: nil)
      @question = question
      @api_key = api_key
    end

    def call
      choices = @question.question_choices.order(:id).map do |c|
        { "id" => c.external_choice_id, "label" => c.label }
      end

      result = build_fetcher.fetch(
        question_body: @question.body,
        choices: choices,
        question_type: @question.question_type
      )

      correct_indices = result[:correct_indices]
      explanation = result[:explanation]
      choice_ids_ordered = @question.question_choices.order(:id).pluck(:id)

      @question.transaction do
        @question.question_correct_answers.destroy_all

        correct_indices.each do |idx|
          next if idx < 0 || idx >= choice_ids_ordered.size

          choice_id = choice_ids_ordered[idx]
          @question.question_correct_answers.create!(question_choice_id: choice_id)
        end

        @question.update!(
          correct_answer_description: explanation.presence,
          correct_answers_fetched_at: Time.current
        )
      end

      { success: true, correct_count: correct_indices.size }
    rescue Gemini::CorrectAnswerFetcher::Error, OpenRouter::CorrectAnswerFetcher::Error => e
      { success: false, error: e.message }
    rescue StandardError => e
      { success: false, error: "#{e.class}: #{e.message}" }
    end

    private

    def build_fetcher
      open_router_key = Rails.application.credentials.open_router_api_key.presence || ENV["OPENROUTER_API_KEY"]
      gemini_key = Rails.application.credentials.gemini_api_key.presence || ENV["GEMINI_API_KEY"]

      if open_router_key.present?
        OpenRouter::CorrectAnswerFetcher.new(api_key: open_router_key)
      else
        Gemini::CorrectAnswerFetcher.new(api_key: gemini_key)
      end
    end
  end
end
