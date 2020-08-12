# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /track', type: :request do
  subject do
    post '/track', params: request_params.to_json, headers: request_headers
    response
  end
  let(:request_headers) { { CONTENT_TYPE: 'application/json' } }

  let(:request_params) do
    [
      {
        'tracking_number' => tracking_number,
        'carrier' => 'FEDEX'
      },
    ]
  end
  let(:tracking_number) { '000000000000001' }
  before { allow(SecureRandom).to receive(:hex).and_return('abcd1234') }

  it do
    expect { subject }.to have_enqueued_job(TrackJob)
    is_expected.to have_http_status(:ok)
    expect(subject.parsed_body['track_id']).to eq('abcd1234')
  end

  context 'missing tracking_number' do
    let(:request_params) { [{ 'carrier' => 'FEDEX' }] }

    it { is_expected.to have_http_status(:unprocessable_entity) }
  end

end
