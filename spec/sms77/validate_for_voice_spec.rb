# frozen_string_literal: true

require 'spec_helper'
require 'sms77/endpoint'
require 'json'

RSpec.describe Sms77, 'validate_for_voice' do
  it 'returns caller id information' do
    number = '491771783130'
    callback_host = Helper.is_http ? `curl http://ipecho.net/plain` : '127.0.0.1'
    callback = "#{callback_host}/callback.php"
    stub = { success: true }

    body = Helper.request(Sms77::Endpoint::VALIDATE_FOR_VOICE, { number: number, callback: callback }, stub)

    expect(body).to be_kind_of(Hash)
    expect(body['success']).to be_boolean
  end
end