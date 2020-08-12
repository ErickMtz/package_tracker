# frozen_string_literal: true

require 'httparty'

class TrackerResponder
  URL = 'http://localhost:3002/track_response'

  def self.send_results(track_id, results)
    HTTParty.post URL,
      headers: { 'Content-Type' => 'application/json' },
      body: { id: track_id, results: results }.to_json
  end
end