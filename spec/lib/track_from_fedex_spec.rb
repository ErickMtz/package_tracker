# frozen_string_literal: true

require 'rails_helper'

describe TrackFromFedex, :model do
  subject { described_class.track([tracking_number]) }

  let(:tracking_number) { '000000000000001' }
  let(:password) { 'test_password' }
  let(:stubbed_request_body) do
    <<~XML.chomp
      <TrackRequest xmlns=\"http://fedex.com/ws/track/v6\">
        <WebAuthenticationDetail>
          <UserCredential>
            <Key>test_key</Key>
            <Password>#{password}</Password>
          </UserCredential>
        </WebAuthenticationDetail>
        <ClientDetail>
          <AccountNumber>test_account_number</AccountNumber>
          <MeterNumber>test_meter</MeterNumber>
          <Localization>
            <LanguageCode>en</LanguageCode>
            <LocaleCode>us</LocaleCode>
          </Localization>
        </ClientDetail>
        <Version>
          <ServiceId>trck</ServiceId>
          <Major>6</Major>
          <Intermediate>0</Intermediate>
          <Minor>0</Minor>
        </Version>
        <PackageIdentifier>
          <Value>#{tracking_number}</Value>
          <Type>TRACKING_NUMBER_OR_DOORTAG</Type>
        </PackageIdentifier>
        <IncludeDetailedScans>true</IncludeDetailedScans>
      </TrackRequest>
    XML
  end
  let(:stubbed_request_headers) do
    {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'User-Agent' => 'Ruby'
    }
  end
  let(:fedex_url) { 'https://wsbeta.fedex.com/xml/' }
  let!(:stubbed_fedex_request) do
    stub_request(:post, fedex_url).
      with(body: stubbed_request_body, headers: stubbed_request_headers).
      to_return(status: 200, body: file_fixture(file_response_body).read)
  end

  context 'fedex auth failed' do
    let(:password) { 'wrong_password' }
    let(:file_response_body) { 'fedex/authentication_failed.xml' }

    before do
      allow(Rails.application.credentials.fedex).
        to receive(:[]).with(:key).and_return('test_key')
      allow(Rails.application.credentials.fedex).
        to receive(:[]).with(:account_number).and_return('test_account_number')
      allow(Rails.application.credentials.fedex).
        to receive(:[]).with(:meter).and_return('test_meter')
      allow(Rails.application.credentials.fedex).
        to receive(:[]).with(:mode).and_return('test')
      allow(Rails.application.credentials.fedex).
        to receive(:[]).with(:password).and_return(password)
    end

    it { expect { subject }.to raise_error(described_class::AuthenticationFailed) }
  end

  context 'fedex service down' do
    let(:file_response_body) { 'fedex/server_down.xml' }

    it do
      is_expected.to eq([
        {
          tracking_number: tracking_number,
          status: 'EXCEPTION',
          message: 'Server Down',
        }
      ])
      expect(stubbed_fedex_request).to have_been_requested.times(described_class::MAX_RETRIES)
    end
  end

  context 'invalid tracking_number' do
    let(:file_response_body) { 'fedex/tracking_number_not_found.xml' }

    it do
      is_expected.to eq([
        {
          tracking_number: tracking_number,
          status: 'EXCEPTION',
          message: 'This tracking number cannot be found. '\
            'Please check the number or contact the sender.',
        }
      ])
      expect(stubbed_fedex_request).to have_been_requested.once
    end
  end

  context 'success tracking' do
    context 'CREATED' do
      let(:file_response_body) do
        'fedex/success_response_with_shipment_information_sent_to_fedex_status.xml'
      end

      it do
        is_expected.to eq([
          {
            tracking_number: tracking_number,
            status: 'CREATED',
            message: 'Shipment information sent to FedEx'
          }
        ])
        expect(stubbed_fedex_request).to have_been_requested.once
      end
    end

    context 'ON_TRANSIT' do
      let(:file_response_body) do
        'fedex/success_response_with_departed_fedex_location_status.xml'
      end

      it do
        is_expected.to eq([
          {
            tracking_number: tracking_number,
            status: 'ON_TRANSIT',
            message: 'Departed FedEx location'
          }
        ])
        expect(stubbed_fedex_request).to have_been_requested.once
      end
    end

    context 'DELIVERED' do
      let(:file_response_body) do
        'fedex/success_response_with_delivered_status.xml'
      end

      it do
        is_expected.to eq([
          {
            tracking_number: tracking_number,
            status: 'DELIVERED',
            message: 'Delivered'
          }
        ])
        expect(stubbed_fedex_request).to have_been_requested.once
      end
    end

    context 'with multiple tracking_numbers' do
      subject { described_class.track([tracking_number, tracking_number2]) }
      let(:file_response_body) do
        'fedex/success_response_with_shipment_information_sent_to_fedex_status.xml'
      end

      let(:tracking_number2) { '000000000000002' }
      let(:stubbed_request_body2) do
        <<~XML.chomp
          <TrackRequest xmlns=\"http://fedex.com/ws/track/v6\">
            <WebAuthenticationDetail>
              <UserCredential>
                <Key>test_key</Key>
                <Password>#{password}</Password>
              </UserCredential>
            </WebAuthenticationDetail>
            <ClientDetail>
              <AccountNumber>test_account_number</AccountNumber>
              <MeterNumber>test_meter</MeterNumber>
              <Localization>
                <LanguageCode>en</LanguageCode>
                <LocaleCode>us</LocaleCode>
              </Localization>
            </ClientDetail>
            <Version>
              <ServiceId>trck</ServiceId>
              <Major>6</Major>
              <Intermediate>0</Intermediate>
              <Minor>0</Minor>
            </Version>
            <PackageIdentifier>
              <Value>#{tracking_number2}</Value>
              <Type>TRACKING_NUMBER_OR_DOORTAG</Type>
            </PackageIdentifier>
            <IncludeDetailedScans>true</IncludeDetailedScans>
          </TrackRequest>
        XML
      end
      let!(:stubbed_fedex_request2) do
        stub_request(:post, fedex_url).
          with(body: stubbed_request_body2, headers: stubbed_request_headers).
          to_return(status: 200, body: file_fixture(file_response_body2).read)
      end
      let(:file_response_body2) { 'fedex/tracking_number_not_found.xml' }

      it do
        is_expected.to eq([
          {
            tracking_number: tracking_number,
            status: 'CREATED',
            message: 'Shipment information sent to FedEx'
          },
          {
            tracking_number: tracking_number2,
            status: 'EXCEPTION',
            message: 'This tracking number cannot be found. '\
              'Please check the number or contact the sender.',
          }
        ])
        expect(stubbed_fedex_request).to have_been_requested.once
        expect(stubbed_fedex_request2).to have_been_requested.once
      end
    end
  end
end