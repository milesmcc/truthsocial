require 'rails_helper'

RSpec.describe GroupNotificationsService, type: :service do
  subject { described_class.new }
  let(:user) { Fabricate(:user, account: Fabricate(:account, whale: true))}
  let(:recipient) { user.account }   
  let(:sender_1) { Fabricate(:account) }
  let(:sender_2) { Fabricate(:account) }
  let(:sender_3) { Fabricate(:account) }
  let(:status_1) { Fabricate(:status, account: recipient) }
  let(:status_2) { Fabricate(:status, account: recipient) }
  let(:type) { :favourite }
  let (:intervals) {[0.5.minutes.seconds.to_i, 10.minutes.seconds.to_i]}

  describe '#call' do
    before do
      stub_const("NOTIFICATION_INTERVALS", intervals)
    end

    context 'when a user interacts with a whale status' do
      it 'queues a job to be performed in 30 seconds' do
        expect do
          Sidekiq::Testing.fake! do
            subject.call(recipient.id, sender_1.id, type, status_1)
          end
        end.to change(GroupNotificationsWorker.jobs, :size).by 1

        queued_job = GroupNotificationsWorker.jobs.first
        span = queued_job['at'] - Time.now.to_f
        expect(span.round).to eq intervals[0]
      end

      it 'stores account id in a Redis list (bucket)' do
        Sidekiq::Testing.fake! do
          subject.call(recipient.id, sender_1.id, type, status_1)
        end  

        keys = Redis.current.smembers("gn:#{recipient.id}:#{type}:#{status_1.id}:#{intervals[0]}")
        expect(keys.length).to eq 1
        expect(keys[0].to_i).to eq sender_1.id
      end

      it 'stores a bucket in a queued Redis list' do
        Sidekiq::Testing.fake! do
          subject.call(recipient.id, sender_1.id, type, status_1)
        end
        keys = Redis.current.zrangebyscore("gn:#{recipient.id}:#{type}:#{status_1.id}:queued_buckets", '-inf', 'inf')
        expect(keys.length).to eq 1
        expect(keys[0].to_i).to eq intervals[0]
      end
    end

    context 'when multiple users interact with the same whale status within 30 seconds' do
      it 'does not queue multiple jobs' do
        expect do
          Sidekiq::Testing.fake! do
            subject.call(recipient.id, sender_1.id, type, status_1)
          end
        end.to change(GroupNotificationsWorker.jobs, :size).by 1

        expect do
          Sidekiq::Testing.fake! do
            subject.call(recipient.id, sender_2.id, type, status_1)
          end
        end.to change(GroupNotificationsWorker.jobs, :size).by 0

        expect(GroupNotificationsWorker.jobs.size).to eq 1
      end

      it 'stores both account ids in a Redis list (bucket)' do
        Sidekiq::Testing.fake! do
          subject.call(recipient.id, sender_1.id, type, status_1)
          subject.call(recipient.id, sender_2.id, type, status_1)
        end
        keys = Redis.current.smembers("gn:#{recipient.id}:#{type}:#{status_1.id}:#{intervals[0]}")

        expect(keys.length).to eq 2
        expect(keys.map(&:to_i)).to eq [sender_1.id, sender_2.id]
      end

      it 'stores only one bucket in a queued Redis list' do
        Sidekiq::Testing.fake! do
          subject.call(recipient.id, sender_1.id, type, status_1)
          subject.call(recipient.id, sender_2.id, type, status_1)
        end
        keys = Redis.current.zrangebyscore("gn:#{recipient.id}:#{type}:#{status_1.id}:queued_buckets", '-inf', 'inf')
        expect(keys.length).to eq 1
        expect(keys[0].to_i).to eq intervals[0]
      end
    end

    context 'when a user interacts with a whale status after 30 seconds' do
      it 'queues a job to be performed every 10 minutes' do
        allow(Time).to receive(:now).and_return(DateTime.new(2022, 04, 04, 20, 10, 0))

        expect do
          Sidekiq::Testing.fake! do
            subject.call(recipient.id, sender_1.id, type, status_1)
          end
        end.to change(GroupNotificationsWorker.jobs, :size).by 1

        queued_jobs = GroupNotificationsWorker.jobs
        span = queued_jobs.first['at'] - Time.now.to_f
        expect(span.round).to eq intervals[0]
        GroupNotificationsWorker.drain 
        
        travel_to(2.minutes.from_now) do
          Sidekiq::Testing.fake! do
            subject.call(recipient.id, sender_2.id, type, status_1)
          end
          queued_jobs = GroupNotificationsWorker.jobs
          expect(queued_jobs.first['at'].to_i).to eq DateTime.new(2022, 04, 04, 20, 20, 0).to_i 
        end
        
        travel_to(14.minutes.from_now) do
          Sidekiq::Testing.fake! do
            subject.call(recipient.id, sender_3.id, type, status_1)
          end
          queued_jobs = GroupNotificationsWorker.jobs
          expect(queued_jobs[1]['at'].to_i).to eq DateTime.new(2022, 04, 04, 20, 30, 0).to_i 
        end

        travel_to(27.minutes.from_now) do
          Sidekiq::Testing.fake! do
            subject.call(recipient.id, sender_3.id, type, status_1)
          end
          queued_jobs = GroupNotificationsWorker.jobs
          expect(queued_jobs[2]['at'].to_i).to eq DateTime.new(2022, 04, 04, 20, 40, 0).to_i 
        end
      end
    end

    context 'when multiple users interact with multiple statuses' do
      let(:type_2) { :reblog }
      it 'queues multiple jobs' do
        expect do
          Sidekiq::Testing.fake! do
            subject.call(recipient.id, sender_1.id, type, status_1)
          end
        end.to change(GroupNotificationsWorker.jobs, :size).by 1

        expect do
          Sidekiq::Testing.fake! do
            subject.call(recipient.id, sender_2.id, type, status_2)
          end
        end.to change(GroupNotificationsWorker.jobs, :size).by 1

        expect do
          Sidekiq::Testing.fake! do
            subject.call(recipient.id, sender_1.id, type_2, status_1)
          end
        end.to change(GroupNotificationsWorker.jobs, :size).by 1

        expect do
          Sidekiq::Testing.fake! do
            subject.call(recipient.id, sender_2.id, type_2, status_1)
          end
        end.to change(GroupNotificationsWorker.jobs, :size).by 0

        expect(GroupNotificationsWorker.jobs.size).to eq 3
      end

      it 'stores account ids per action type' do
        Sidekiq::Testing.fake! do
          subject.call(recipient.id, sender_1.id, type, status_1)
          subject.call(recipient.id, sender_2.id, type, status_2)
          subject.call(recipient.id, sender_1.id, type_2, status_1)
          subject.call(recipient.id, sender_2.id, type_2, status_1)
        end

        keys_1 = Redis.current.smembers("gn:#{recipient.id}:#{type}:#{status_1.id}:#{intervals[0]}")
        keys_2 = Redis.current.smembers("gn:#{recipient.id}:#{type}:#{status_2.id}:#{intervals[0]}")
        keys_3 = Redis.current.smembers("gn:#{recipient.id}:#{type_2}:#{status_1.id}:#{intervals[0]}")

        expect(keys_1.length).to eq 1
        expect(keys_1.map(&:to_i)).to eq [sender_1.id]

        expect(keys_2.length).to eq 1
        expect(keys_2.map(&:to_i)).to eq [sender_2.id]

        expect(keys_3.length).to eq 2
        expect(keys_3.map(&:to_i)).to eq [sender_1.id, sender_2.id]
      end

      it 'stores a bucket per status per action type  in a queued Redis list' do
        Sidekiq::Testing.fake! do
          subject.call(recipient.id, sender_1.id, type, status_1)
          subject.call(recipient.id, sender_2.id, type, status_2)
          subject.call(recipient.id, sender_1.id, type_2, status_1)
          subject.call(recipient.id, sender_2.id, type_2, status_1)
        end

        keys_1 = Redis.current.zrangebyscore("gn:#{recipient.id}:#{type}:#{status_1.id}:queued_buckets", '-inf', 'inf')
        keys_2 = Redis.current.zrangebyscore("gn:#{recipient.id}:#{type}:#{status_2.id}:queued_buckets", '-inf', 'inf')
        keys_3 = Redis.current.zrangebyscore("gn:#{recipient.id}:#{type_2}:#{status_1.id}:queued_buckets", '-inf', 'inf')
        keys_4 = Redis.current.zrangebyscore("gn:#{recipient.id}:#{type_2}:#{status_2.id}:queued_buckets", '-inf', 'inf')

        expect(keys_1.length).to eq 1
        expect(keys_2.length).to eq 1
        expect(keys_3.length).to eq 1
        expect(keys_4.length).to eq 0
      end
    end
  end
end
