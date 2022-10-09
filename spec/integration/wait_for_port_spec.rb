# WarmBlanket: Ruby gem for warming up web services on boot
# Copyright (C) 2017 Talkdesk, Inc. <tech@talkdesk.com>
#
# This file is part of WarmBlanket.
#
# WarmBlanket is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# WarmBlanket is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with WarmBlanket.  If not, see <http://www.gnu.org/licenses/>.

require 'warm_blanket/wait_for_port'
require 'socket'
require 'timecop'
require 'time'

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
      let(:expected_tries) { 10 }
      let(:time_deadline) { Time.local(2017) + expected_tries }
      let(:optional_arguments) { {time_deadline: time_deadline} }

      before do
        allow(subject).to receive(:sleep)
      end

      after do
        Timecop.return
      end

      it do
        Timecop.freeze(time_deadline) # deadline already hit

        expect(call).to be false
      end

      it 'tries at least once' do
        Timecop.freeze(time_deadline) # deadline already hit

        expect(TCPSocket).to receive(:new) { raise_connection_error }

        call
      end

      it 'retries until the time_deadline has passed' do
        Timecop.freeze(Time.local(2017))

        expect(TCPSocket).to receive(:new).exactly(expected_tries).times do
          tick_clock_one_second
          raise_connection_error
        end

        call
      end

      it 'sleeps one second between tries' do
        Timecop.freeze(Time.local(2017))
        should_sleep_now = false

        allow(TCPSocket).to receive(:new) do
          should_sleep_now = true
          raise_connection_error
        end

        expect(subject).to receive(:sleep).with(1).exactly(expected_tries).times do
          expect(should_sleep_now).to be true
          should_sleep_now = false

          tick_clock_one_second
        end

        call
      end

      context 'when service becomes available after the n-th try' do
        it do
          Timecop.freeze(Time.local(2017))

          attempts = 0

          allow(TCPSocket).to receive(:new) do
            attempts += 1
            if attempts > 2
              instance_double(TCPSocket, close: nil)
            else
              raise_connection_error
            end
          end

          expect(call).to be true
        end
      end
    end
  end

  def tick_clock_one_second
    Timecop.freeze(Time.now + 1)
  end

  def raise_connection_error
    raise Errno::ECONNREFUSED
  end
end
