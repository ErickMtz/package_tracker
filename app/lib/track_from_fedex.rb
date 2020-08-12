# frozen_string_literal: true

class TrackFromFedex
  AuthenticationFailed = Class.new(StandardError)

  MAX_RETRIES = 3

  CREATED = [
    'Shipment information sent to FedEx',
  ].freeze

  ON_TRANSIT = [
    'At Pickup',
    'Picked up',
    'In FedEx possession',
    'At local FedEx facility',
    'Left FedEx origin facility',
    'Arrived at FedEx location',
    'Departed FedEx location',
    'In transit',
    'At FedEx destination facility',
    'On FedEx vehicle for delivery',
  ].freeze

  DELIVERED = [
    'Delivered',
  ].freeze

  def self.track(tracking_numbers)
    fedex = Fedex::Shipment.new(Rails.application.credentials.fedex)

    tracking_numbers.map do |tracking_number|
      retries = 0
      begin
        results = fedex.track(tracking_number: tracking_number)
        {
          tracking_number: tracking_number,
          status: status_code(results.first.status),
          message: results.first.status,
        }
      rescue Fedex::RateError => e
        message = e.message.strip
        raise AuthenticationFailed if message.casecmp?('Authentication Failed')
        if message.casecmp?('Server Down')
          retries += 1
          retry if retries < MAX_RETRIES
        end
        { tracking_number: tracking_number, status: 'EXCEPTION', message: message }
      end
    end
  end

  def self.status_code(status)
    return 'CREATED' if CREATED.include?(status)
    return 'ON_TRANSIT' if ON_TRANSIT.include?(status)
    return 'DELIVERED' if DELIVERED.include?(status)
    'EXCEPTION'
  end
end
