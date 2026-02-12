# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Room subscriptions are public (by room_code); no auth required.
    identified_by :current_connection_id

    def connect
      self.current_connection_id = SecureRandom.uuid
    end
  end
end
