# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrackJob, type: :active_job do
  subject { described_class.perform_now(track_id, tracking_info) }

  let(:track_id) { '123456789' }
  let(:tracking_info) do
    [
      { tracking_number: '000000000000001', carrier: 'FEDEX' },
      { tracking_number: '000000000000002', carrier: 'fedex' },
      { tracking_number: '000000000000003', carrier: 'UNKOWN' },
      { tracking_number: '000000000000004', carrier: 'UNKOWN' },
      { tracking_number: '000000000000005' },

    ]
  end

  let(:expected_tracking_info) do
    [
      { tracking_number: '000000000000001', status: 'DELIVERED', message: 'Delivered' },
      { tracking_number: '000000000000002', status: 'ON_TRANSIT', message: 'In transit' },
      { tracking_number: '000000000000003', status: 'EXEPTION', message: 'Unknown Carrier' },
      { tracking_number: '000000000000004', status: 'EXEPTION', message: 'Unknown Carrier' },
      { tracking_number: '000000000000005', status: 'EXEPTION', message: 'Unknown Carrier' }
    ]
  end

  before do
    allow(TrackFromFedex).
      to receive(:track).with(['000000000000001', '000000000000002']).
      and_return([
        { tracking_number: '000000000000001', status: 'DELIVERED', message: 'Delivered' },
        { tracking_number: '000000000000002', status: 'ON_TRANSIT', message: 'In transit' },
      ])
    allow(TrackerResponder).to receive(:send_results).with(track_id, expected_tracking_info).
      and_return(nil)
  end

  it { is_expected.to eq(expected_tracking_info) }

end