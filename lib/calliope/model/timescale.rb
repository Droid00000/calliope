# frozen_string_literal: true

module Calliope
  class Timescale
    # @return [Integer]
    attr_reader :rate

    # @return [Integer]
    attr_reader :speed

    # @return [Integer]
    attr_reader :pitch

    # @param payload [Hash]
    def initialize(payload)
      @rate = payload["rate"]
      @speed = payload["speed"]
      @pitch = payload["pitch"]
    end
  end
end