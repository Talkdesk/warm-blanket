require 'warm_blanket/requester'
require 'webmock/rspec'

RSpec.describe WarmBlanket::Requester do
  let(:base_url) { 'http://localhost:1234' }
  let(:default_headers) { {'X-Foo': '123'} }
  let(:endpoints) { [{get: '/apps', headers: {'X-Bar': '456'}}] }

  subject {
    described_class.new(base_url: base_url, default_headers: default_headers, endpoints: endpoints)
  }

  describe '#call' do
    let(:call) { subject.call }

    let(:request_url) { "#{base_url}/apps" }

    before do
      WebMock.enable!
      stub_request(:get, request_url)
    end

    after do
      WebMock.disable!
    end

    it 'performs a get request to the configured endpoints' do
      call

      expect(a_request(:get, request_url)).to have_been_made
    end

    it 'includes the default headers' do
      call

      expect(a_request(:get, request_url).with(headers: {'X-Foo' => '123'}))
        .to have_been_made
    end

    it 'includes the configured headers' do
      call

      expect(a_request(:get, request_url).with(headers: {'X-Bar' => '456'}))
        .to have_been_made
    end

    context 'when configured headers include headers also in default headers' do
      let(:default_headers) { {'X-Bar': '42'} }

      it 'overrides default headers with configured headers' do
        call

        expect(a_request(:get, request_url).with(headers: {'X-Bar' => '456'}))
          .to have_been_made
      end
    end

    context 'when multiple endpoints are configured' do
      let(:endpoints) { [{get: '/1'}, {get: '/2'}, {get: '/3'}] }

      it 'cycles between the endpoints on every call' do
        stub_request(:get, "#{base_url}/1")
        stub_request(:get, "#{base_url}/2")
        stub_request(:get, "#{base_url}/3")

        subject.call
        expect(a_request(:get, "#{base_url}/1")).to have_been_made

        subject.call
        expect(a_request(:get, "#{base_url}/2")).to have_been_made

        subject.call
        expect(a_request(:get, "#{base_url}/3")).to have_been_made

        subject.call
        expect(a_request(:get, "#{base_url}/1")).to have_been_made.times(2)
      end
    end

    context 'when endpoints use the post verb' do
      let(:endpoints) { [{post: '/foo', body: '{"hello":"world"}'}] }

      let(:post_request_url) { "#{base_url}/foo" }

      before do
        stub_request(:post, post_request_url)
      end

      it 'performs a post request to the configured endpoints' do
        call

        expect(a_request(:post, post_request_url)).to have_been_made
      end

      it 'includes the specified body in the post request' do
        call

        expect(a_request(:post, post_request_url).with(body: '{"hello":"world"}')).to have_been_made
      end
    end

    context 'when an unsupported http verb is used' do
      let(:endpoints) { [{delete: '/foo'}] }

      it do
        expect { call }.to raise_error(described_class::InvalidHTTPVerb)
      end
    end
  end
end
