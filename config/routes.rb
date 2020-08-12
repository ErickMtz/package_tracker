# frozen_string_literal: true

Rails.application.routes.draw do
  post '/track', to: 'track#track'
end
