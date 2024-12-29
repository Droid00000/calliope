# frozen_string_literal: true

# The websocket client internally used by calliope.
module Calliope
  # The API namespace.
  module API
    # The socket wrapper class.
    class Socket
      # @return [String]
      attr_reader :url

      # @return [Boolean]
      attr_reader :dead

      # @return [Thread]
      attr_reader :thread

      # @param user_id [Integer] Snowflake ID of the bot that uses the lavalink node.
      # @param address [String] wss:// address used for connecting to the lavalink node.
      # @param password [String] Password used for connecting to the lavalink node.
      # @param session_id [String, nil] ID of the previous session to resume.
      def initialize(url, password, user_id, session_id, client)
        @dead = false
        @client = client
        @driver = WebSocket::Driver.client(self)
        @driver.set_header("User-Id", user_id&.to_i)
        @driver.set_header("Authorization", password)
        @driver.set_header("Session-Id", session_id) if session_id
        @driver.set_header("Client-Name", "Calliope/#{CALLIOPE::VERSION}")
        @driver.on(:message) { |frame| handle_dispatch(JSON.parse(frame.data)) }

        @url = URI.parse(create_url(url))
        @tcp = TCPSocket.new(@url.host || "localhost", @url.port)
        @thread = Thread.new { @driver.parse(@tcp.read(1)) until @dead }

        @driver.start
      end

      # Handles a dispatch from the Websocket.
      def handle_dispatch(dispatch)
        case dispatch["op"]
        when "playerUpdate"
          @client.__send__(:notify_update, dispatch)
        when "ready"
          @client.__send__(:notify_ready, dispatch)
        when "stats"
          @client.__send__(:notify_stats, dispatch)
        when "event"
          @client.__send__(:notify_event, dispatch)
        end
      end

      # Create a new WS URL.
      # @param address [String]
      # @return [String] The URL to use.
      def create_url(address)
        "ws#{address.delete_prefix("http")}/websocket"
      end

      # Send data to the socket.
      # @param data [String]
      def send(data)
        @driver.text(data)
      end

      # Write data to the socket.
      def write(data)
        @tcp.write(data)
      end

      # Close the websocket driver.
      def close
        @driver.close
      end
    end
  end
end
