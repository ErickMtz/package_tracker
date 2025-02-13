# frozen_string_literal: true

class TrackJob < ApplicationJob

  CARRIERS = [
    'Fedex'
  ].freeze

  after_perform { TrackerResponder.send_results(@track_id, @results) }

  def perform(track_id, tracking_info)
    @track_id = track_id
    @results = []

    CARRIERS.each do |carrier|
      tracking_info_for_carrier = tracking_info.select { |info| info[:carrier]&.casecmp?(carrier) }
      tracking_info = tracking_info - tracking_info_for_carrier
      tracking_numbers = tracking_info_for_carrier.map { |info| info[:tracking_number] }
      @results.push(*"TrackFrom#{carrier}".constantize.public_send(:track, tracking_numbers))
    end

    @results.push(*tracking_info.map { |info| unknown_carrier_response(info[:tracking_number]) })

    @results
  end

private
  def unknown_carrier_response(tracking_number)
    { tracking_number: tracking_number, status: 'EXEPTION',  message: 'Unknown Carrier' }
  end

end
