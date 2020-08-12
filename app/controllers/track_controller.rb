# frozen_string_literal: true

class TrackController < ApplicationController

  rescue_from ActionController::ParameterMissing, with: -> { head(:unprocessable_entity) }

  def track
    track_id = SecureRandom.hex
    TrackJob.perform_later(track_id, track_params)
    render json: { track_id: track_id }
  end

  def track_params
    params.require(:_json).map do |track_param|
      track_param.permit(:tracking_number, :carrier).tap do |permited_track_params|
        permited_track_params.require(:tracking_number)
      end
    end
  end
end
