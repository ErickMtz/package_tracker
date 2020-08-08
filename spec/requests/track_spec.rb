require 'rails_helper'

RSpec.describe 'POST /track', type: :request do
  context 'fedex auth failed' do
    it 'returns unauthorized'
  end

  context 'fedex service down' do
    it 'tries n times'
    it 'returns status: EXCEPTION'
  end

  context 'missing tracking_number' do
    it 'returns unprocessable entity'
  end

  context 'missing carrier' do
    it 'returns status: EXCEPTION'
  end

  context 'unsopported carrier' do
    it 'returns status: EXCEPTION'
  end

  context 'invalid tracking_number' do
    it 'returns status: EXCEPTION'
  end

  context 'success tracking' do
    context 'CREATED' do
      it 'returns status: CREATED'
    end
    context 'ON_TRANSIT' do
      it 'returns status: ON_TRANSIT'
    end
    context 'DELIVERED' do
      it 'returns status: DELIVERED'
    end
  end

end
