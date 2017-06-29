require 'warm_blanket/wait_for_port'
require 'socket'

RSpec.describe WarmBlanket::WaitForPort do
  let(:port) { (2**10...2**16).to_a.sample }
  let(:default_hostname) { 'localhost' }
  let(:optional_arguments) { {} }

  subject { described_class.new(port: port, **optional_arguments) }

  describe '.new' do
    context 'when port is specified as a string' do
      let(:port) { '5000' }

      it 'returns a new instance' do
        subject
      end
    end

    context 'when invalid port is specified' do
      let(:port)  { 'over 9000' }

      it do
        expect { subject }.to raise_error(described_class::InvalidPort)
      end
    end
  end

  describe '#call' do
    let(:call) { subject.call }

    context 'when service is available' do
      let!(:open_socket) { TCPServer.open(port) }
      let!(:server_background_thread) { Thread.new { open_socket.accept } }

      after do
        server_background_thread.join
        open_socket.close
      end

      it do
        expect(call).to be true
      end
    end

    context 'when service is not available' do
      let(:tries_limit) { 3 }
      let(:optional_arguments) { {tries_limit: tries_limit} }

      before do
        allow(subject).to receive(:sleep)
      end

      it do
        expect(call).to be false
      end

      it 'retries tries_limit times' do
        expect(TCPSocket).to receive(:new)
          .with(default_hostname, port).exactly(tries_limit).times.and_call_original

        call
      end

      it 'sleeps one second between tries' do
        should_sleep_now = false

        allow(TCPSocket).to receive(:new) do
          should_sleep_now = true
          raise Errno::ECONNREFUSED
        end

        expect(subject).to receive(:sleep).with(1).exactly(tries_limit - 1).times do
          expect(should_sleep_now).to be true
          should_sleep_now = false
        end

        call
      end

      context 'when service becomes available after the n-th try' do
        it do
          attempts = 0

          allow(TCPSocket).to receive(:new) do
            attempts += 1
            if attempts > 2
              instance_double(TCPSocket, close: nil)
            else
              raise Errno::ECONNREFUSED
            end
          end

          expect(call).to be true
        end
      end
    end
  end
end
