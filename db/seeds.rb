# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Load Ruby Silver question bank from exam_ruby_silver/*.json
Rake::Task["db:seed_question_bank"].invoke

# Default host user for creating exams and rooms (development only; set HOST_SEED_PASSWORD in production)
if Rails.env.development? || ENV["HOST_SEED_PASSWORD"].present?
  password = ENV["HOST_SEED_PASSWORD"].presence || "hostpassword"
  User.find_or_initialize_by(email: "host@example.com").tap do |u|
    if u.new_record?
      u.password = password
      u.role = "host"
      u.save!
    end
  end
end
