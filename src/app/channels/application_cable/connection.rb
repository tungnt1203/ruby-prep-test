# frozen_string_literal: true

module ApplicationCable
  # One connection per WebSocket. See Action Cable Overview: Connections, Consumers, Channels.
  # We allow unauthenticated connections so anyone with the room link can subscribe to Turbo Streams
  # (stream name is signed; channel verifies it). Use identified_by for connection identity.
  class Connection < ActionCable::Connection::Base
    identified_by :current_connection_id

    def connect
      self.current_connection_id = SecureRandom.uuid
    end
  end
end
