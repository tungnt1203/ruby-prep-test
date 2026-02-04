# frozen_string_literal: true

module Gemini
  # Calls Google Gemini API to produce an answer key + explanation for MCQs.
  # Supports single_choice (one answer) and multi_choice (multiple answers).
  class CorrectAnswerFetcher
    # Default model list with fallbacks.
    MODELS = %w[gemini-3-flash-preview gemini-1.5-flash gemini-pro].freeze

    class Error < StandardError; end
    class MissingApiKey < Error; end
    class InvalidResponse < Error; end

    def initialize(api_key: nil)
      @api_key = api_key.presence || ENV["GEMINI_API_KEY"]
      raise MissingApiKey, "Missing GEMINI_API_KEY" if @api_key.blank?
    end

    # @return [Hash] { correct_indices: [0,1,...], explanation: "..." } (indices 0-based)
    def fetch(question_body:, choices:, question_type: "single_choice")
      prompt = build_prompt(question_body, choices, question_type)
      response_text = call_api(prompt)
      parse_response(response_text, question_type)
    rescue InvalidResponse => e
      # Try fallbacks when the error looks model/API-specific.
      if e.message.include?("API 404") || e.message.include?("API 400") || e.message.include?("No candidate")
        try_fallback_models(prompt, question_type, e)
      else
        raise
      end
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
        You are an expert grading multiple choice questions. Answer in valid JSON only, no markdown.

        Question:
        #{question_body}

        Options (numbered 1 to #{choices.size}):
        #{options_text}

        #{instruction}
        Return JSON with:
        - "#{correct_key}": #{single ? "integer (1-based, the number of the correct option)" : "array of integers (1-based numbers of all correct options)"}
        - "explanation": short explanation in English

        Example format: {"#{correct_key}": #{single ? "2" : "[1, 3]"}, "explanation": "..."}
      PROMPT
    end

    def try_fallback_models(prompt, question_type, first_error)
      MODELS.drop(1).each do |model|
        response_text = call_api(prompt, model: model)
        return parse_response(response_text, question_type)
      rescue InvalidResponse
        next
      end
      raise first_error
    end

    def call_api(prompt, model: MODELS.first)
      # v1beta/models/MODEL_ID:generateContent (non-streaming).
      url = "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent"
      body = {
        contents: [
          {
            role: "user",
            parts: [{ text: prompt }]
          }
        ],
        generationConfig: build_generation_config(model)
      }

      response = Faraday.post(
        "#{url}?key=#{@api_key}",
        body.to_json,
        "Content-Type" => "application/json"
      )

      unless response.success?
        err_msg = parse_error_body(response.body)
        raise InvalidResponse, "API #{response.status}: #{err_msg}"
      end

      data = JSON.parse(response.body)
      candidate = data.dig("candidates", 0)

      unless candidate
        feedback = data.dig("promptFeedback", "blockReason") || data.dig("promptFeedback", "blockReasonMessage")
        raise InvalidResponse, "No candidate returned by model#{feedback ? " (#{feedback})" : ""}"
      end

      # Some Gemini models may return multiple parts (e.g., "thinking" + JSON).
      parts = candidate.dig("content", "parts").to_a
      text = parts.map { |p| p["text"].to_s }.join("\n").strip
      raise InvalidResponse, "Empty response" if text.blank?

      text
    end

    def build_generation_config(model)
      config = {
        temperature: 0.1,
        maxOutputTokens: 2048
      }
      # gemini-3: enable thinking config.
      config[:thinkingConfig] = { thinkingLevel: "HIGH" } if model.include?("gemini-3")
      config[:responseMimeType] = "application/json" if model.include?("1.5")
      config
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

    # Extracts a JSON object from a potentially noisy response.
    def extract_json_string(text)
      return text.strip if text.blank?

      # 1) ```json ... ```
      if text.include?("```")
        m = text.match(/```(?:json)?\s*([\s\S]*?)```/)
        return m[1].strip if m && m[1].strip.present?
      end

      # 2) Look for an object containing "explanation" and correct_index/indices.
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
      %w[correct_index correct_indices].each do |key|
        needle = "{\"#{key}\""
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

      text.strip
    end
  end
end
