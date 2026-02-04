# frozen_string_literal: true

module OpenRouter
  # Calls OpenRouter Chat Completions API to produce an answer key + explanation.
  # Keeps the same interface as Gemini::CorrectAnswerFetcher.
  class CorrectAnswerFetcher
    API_URL = "https://openrouter.ai/api/v1/chat/completions"
    DEFAULT_MODEL = "google/gemini-2.5-flash-lite"

    class Error < StandardError; end
    class MissingApiKey < Error; end
    class InvalidResponse < Error; end

    def initialize(api_key: Rails.application.credentials.open_router_api_key)
      @api_key = api_key.presence
      raise MissingApiKey, "Missing OPENROUTER_API_KEY" if @api_key.blank?
    end

    # @return [Hash] { correct_indices: [0,1,...], explanation: "..." } (indices 0-based)
    def fetch(question_body:, choices:, question_type: "single_choice")
      prompt = build_prompt(question_body, choices, question_type)
      response_text = call_api(prompt)
      parse_response(response_text, question_type)
    end

    private

    def build_prompt(question_body, choices, question_type)
      options_text = choices.each_with_index.map do |c, i|
        "#{i + 1}. #{c["label"] || c[:label]}"
      end.join("\n")

      single = question_type == "single_choice"
      correct_key = single ? "correct_index" : "correct_indices"
      instruction = single ? "Exactly one option is correct." : "One or more options may be correct."

      <<~PROMPT
        You are an expert at grading multiple choice questions.

        You MUST return ONLY a valid JSON object.
        Do NOT include markdown, comments, extra text, or explanations outside JSON.

        Question:
        #{question_body}

        Options (numbered starting from 1):
        #{options_text}

        Instructions:
        #{instruction}

        Rules:
        - If there is ONE correct answer, return an integer
        - If there are MULTIPLE correct answers, return an array of integers
        - Numbers must be 1-based (match the option numbers)
        - explanation must be a short string in English
        - Output must be valid JSON that Ruby can parse with JSON.parse

        Response format EXACTLY:

        {
          "#{correct_key}": #{single ? "INTEGER" : "[INTEGER, INTEGER]"},
          "explanation": "SHORT EXPLANATION"
        }

        Do not output anything else.
      PROMPT
    end

    def call_api(prompt)
      body = {
        model: DEFAULT_MODEL,
        messages: [
          { role: "user", content: prompt }
        ]
      }

      response = Faraday.post(
        API_URL,
        body.to_json,
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      )

      unless response.success?
        err_msg = parse_error_body(response.body)
        raise InvalidResponse, "API #{response.status}: #{err_msg}"
      end

      data = JSON.parse(response.body)
      text = data.dig("choices", 0, "message", "content")
      raise InvalidResponse, "Empty response" if text.blank?

      text.strip
    end

    def parse_error_body(body)
      return body.to_s[0..200] if body.blank?
      data = JSON.parse(body) rescue nil
      return body.to_s[0..200] unless data.is_a?(Hash)
      data.dig("error", "message") || data.dig("error", "status") || body.to_s[0..200]
    end

    def parse_response(text, question_type)
      json_str = extract_json_string(text)
      data = JSON.parse(json_str)
      correct_key = question_type == "single_choice" ? "correct_index" : "correct_indices"
      raw = data[correct_key] || data[correct_key.to_s]
      indices_1based = Array.wrap(raw).map { |n| n.to_i }
      indices_0based = indices_1based.map { |i| i - 1 }.reject { |i| i < 0 }

      {
        correct_indices: indices_0based,
        explanation: data["explanation"].to_s.strip.presence || ""
      }
    rescue JSON::ParserError => e
      raise InvalidResponse, "Invalid JSON: #{e.message}"
    end

    # Extracts a JSON object from a potentially fenced/noisy response.
    def extract_json_string(text)
      return text.to_s.strip if text.blank?

      # 1) ```json ... ```
      if text.include?("```")
        m = text.match(/```(?:json)?\s*([\s\S]*?)```/)
        return m[1].strip if m && m[1].strip.present?
      end

      # 2) Try to locate an object containing explanation + correct_index/indices.
      key = "explanation"
      idx = text.rindex(key)
      if idx
        start = text.rindex(/\{/, idx)
        if start
          depth = 0
          i = start
          while i < text.length
            c = text[i]
            depth += 1 if c == "{"
            depth -= 1 if c == "}"
            if depth == 0
              candidate = text[start..i]
              if candidate.include?(key) && (candidate.include?("correct_index") || candidate.include?("correct_indices"))
                return candidate
              end
            end
            i += 1
          end
        end
      end

      # 3) Single-line JSON.
      text.each_line do |line|
        line = line.strip
        next if line.blank? || line.start_with?("//") || line.start_with?("#")
        return line if line.start_with?("{") && line.end_with?("}")
      end

      # 4) Scan from a known key and read until braces match.
      %w[correct_index correct_indices].each do |key2|
        needle = "{\"#{key2}\""
        pos = 0
        while (pos = text.index(needle, pos))
          depth = 0
          i = pos
          while i < text.length
            c = text[i]
            depth += 1 if c == "{"
            depth -= 1 if c == "}"
            if depth == 0
              candidate = text[pos..i]
              begin
                JSON.parse(candidate)
                return candidate
              rescue JSON::ParserError
                break
              end
            end
            i += 1
          end
          pos += 1
        end
      end

      text.to_s.strip
    end
  end
end
