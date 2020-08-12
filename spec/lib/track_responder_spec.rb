# frozen_string_literal: true

require 'rails_helper'

describe TrackerResponder, :model do
  describe '#send_results' do
    subject { described_class.send_results(track_id, results) }

    let(:track_id) { '123456789' }
    let!(:stubbed_fedex_request) do
      stub_request(:post, described_class::URL).
        with(
          body: { id: track_id, results: results }.to_json,
          headers: {'Content-Type' => 'application/json'},
        ).
        to_return(status: 200)
    end

    let(:results) do
      [
        { tracking_number: '000000000000001', status: 'DELIVERED', message: 'Delivered' },
        { tracking_number: '000000000000002', status: 'ON_TRANSIT', message: 'In transit' },
        { tracking_number: '000000000000003', status: 'EXEPTION', message: 'Unknown Carrier' },
        { tracking_number: '000000000000004', status: 'EXEPTION', message: 'Unknown Carrier' },
        { tracking_number: '000000000000005', status: 'EXEPTION', message: 'Unknown Carrier' }
      ]
    end

    it do
      subject
      expect(stubbed_fedex_request).to have_been_requested.once
    end
  end
end