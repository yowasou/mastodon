# frozen_string_literal: true

require 'rails_helper'

describe WebPushNotificationWorker do
  subject { described_class.new }

  describe '#perform' do
    let!(:alice)              { Fabricate(:user).account }
    let!(:subscription)       { Fabricate(:web_push_subscription) }
    let!(:session_activation) { Fabricate(:session_activation, user: alice.user, web_push_subscription: subscription) }
    let!(:notification)       { Fabricate(:notification, account: alice, activity: Fabricate(:favourite)) }
    
    it 'sends webpush payload' do
      allow(Webpush).to receive(:payload_send).and_return(nil)
      subject.perform(session_activation.id, notification.id)
      expect(Webpush).to have_received(:payload_send)
    end
  end
end
