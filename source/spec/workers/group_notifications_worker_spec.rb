require 'rails_helper'

RSpec.describe GroupNotificationsWorker, type: :service do
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

  describe '#perform' do
    before do
      stub_const("NOTIFICATION_INTERVALS", intervals)
    end

    context 'when a job is queued with an action from a signle user' do
      let(:base_key) { "gn:#{recipient.id}:#{type}:#{status_1.id}" }
      
      it 'notifies without count ' do
        Redis.current.sadd("#{base_key}:#{intervals[0]}", sender_1.id)
        Redis.current.zadd("#{base_key}:queued_buckets", Time.now.to_i, intervals[0])
        
        subject.perform(recipient.id, type, status_1.id, intervals[0])
        
        expect(Notification.all.count).to eq 1
        expect(Notification.where(activity_id: status_1.id, activity_type: "Status", account_id: recipient.id, from_account_id: sender_1.id, count: nil, type: 'favourite_group')).to be_present
      end

      it 'updates the current interval ' do
        Redis.current.sadd("#{base_key}:#{intervals[0]}", sender_1.id)
        Redis.current.zadd("#{base_key}:queued_buckets", Time.now.to_i, intervals[0])
        
        subject.perform(recipient.id, type, status_1.id, intervals[0])
        
        expect(Redis.current.get("#{base_key}:current_interval").to_i).to eq intervals[1]
      end

    end

    context 'when a job is queued with an action from multple users' do
      let(:base_key) { "gn:#{recipient.id}:#{type}:#{status_1.id}" }
      
      it 'notifies with count ' do
        Redis.current.sadd("#{base_key}:#{intervals[0]}", sender_1.id)
        Redis.current.sadd("#{base_key}:#{intervals[0]}", sender_2.id)
        Redis.current.zadd("#{base_key}:queued_buckets", Time.now.to_i, intervals[0])
        
        subject.perform(recipient.id, type, status_1.id, intervals[0])
        
        expect(Notification.all.count).to eq 1
        expect(Notification.where(activity_id: status_1.id, activity_type: "Status", account_id: recipient.id, from_account_id: sender_1.id, count: 2, type: 'favourite_group')).to be_present
      end
    end


    context 'when a job is queued with an action from multple users and the status is deleted' do
      let(:base_key) { "gn:#{recipient.id}:#{type}:#{status_1.id}" }

      it 'doesnt notify' do
        Redis.current.sadd("#{base_key}:#{intervals[0]}", sender_1.id)
        Redis.current.sadd("#{base_key}:#{intervals[0]}", sender_2.id)
        Redis.current.zadd("#{base_key}:queued_buckets", Time.now.to_i, intervals[0])

        subject.perform(recipient.id, type, nil, intervals[0])

        expect(Notification.all.count).to eq 0
      end
    end

    context 'when there is an old job which is not processed' do
      let(:base_key) { "gn:#{recipient.id}:#{type}:#{status_1.id}" }
      
      it 'notifies for all unprocessed jobs ' do
        Redis.current.sadd("#{base_key}:interval1", sender_1.id)
        Redis.current.zadd("#{base_key}:queued_buckets", Time.now.to_i, "interval1")

        Redis.current.sadd("#{base_key}:interval2", sender_2.id)
        Redis.current.zadd("#{base_key}:queued_buckets", Time.now.to_i + 1 , "interval2")

        Redis.current.sadd("#{base_key}:interval3", sender_3.id)
        Redis.current.zadd("#{base_key}:queued_buckets", Time.now.to_i + 2, "interval3")

        subject.perform(recipient.id, type, status_1.id, "interval2")
        
        expect(Notification.all.count).to eq 1
        expect(Notification.where(activity_id: status_1.id, activity_type: "Status", account_id: recipient.id, from_account_id: sender_1.id, count: 2, type: 'favourite_group')).to be_present
        expect(Redis.current.zrangebyscore("#{base_key}:queued_buckets", "-inf",  "+inf")).to eq ["interval3"]
      end
    end

    context 'when multiple job/actions are queued for a single status' do
      let(:type_2) { :reblog }
      let(:base_key_1) { "gn:#{recipient.id}:#{type}:#{status_1.id}" }
      let(:base_key_2) { "gn:#{recipient.id}:#{type_2}:#{status_1.id}" }
      
      it 'notifies with multiple notifications' do
        Redis.current.sadd("#{base_key_1}:#{intervals[0]}", sender_1.id)
        Redis.current.zadd("#{base_key_1}:queued_buckets", Time.now.to_i, intervals[0])

        Redis.current.sadd("#{base_key_2}:#{intervals[0]}", sender_2.id)
        Redis.current.zadd("#{base_key_2}:queued_buckets", Time.now.to_i, intervals[0])
        
        subject.perform(recipient.id, type, status_1.id, intervals[0])
        subject.perform(recipient.id, type_2, status_1.id, intervals[0])
        
        expect(Notification.all.count).to eq 2
        expect(Notification.where(activity_id: status_1.id, activity_type: "Status", account_id: recipient.id, from_account_id: sender_1.id, count: nil, type: 'favourite_group')).to be_present
        expect(Notification.where(activity_id: status_1.id, activity_type: "Status", account_id: recipient.id, from_account_id: sender_2.id, count: nil,type: 'reblog_group')).to be_present
      end
    end


    context 'when multiple job/actions are queued for multiple statuses' do
      let(:type_2) { :reblog }
      let(:base_key_1) { "gn:#{recipient.id}:#{type}:#{status_1.id}" }
      let(:base_key_2) { "gn:#{recipient.id}:#{type}:#{status_2.id}" }

      let(:base_key_3) { "gn:#{recipient.id}:#{type_2}:#{status_1.id}" }
      let(:base_key_4) { "gn:#{recipient.id}:#{type_2}:#{status_2.id}" }
    
      it 'notifies with multiple notifications' do
        Redis.current.sadd("#{base_key_1}:#{intervals[0]}", sender_1.id)
        Redis.current.zadd("#{base_key_1}:queued_buckets", Time.now.to_i, intervals[0])

        Redis.current.sadd("#{base_key_2}:#{intervals[0]}", sender_2.id)
        Redis.current.zadd("#{base_key_2}:queued_buckets", Time.now.to_i, intervals[0])

        Redis.current.sadd("#{base_key_3}:#{intervals[0]}", sender_1.id)
        Redis.current.zadd("#{base_key_3}:queued_buckets", Time.now.to_i, intervals[0])

        Redis.current.sadd("#{base_key_4}:#{intervals[0]}", sender_2.id)
        Redis.current.zadd("#{base_key_4}:queued_buckets", Time.now.to_i, intervals[0])
        
        subject.perform(recipient.id, type, status_1.id, intervals[0])
        subject.perform(recipient.id, type, status_2.id, intervals[0])
        subject.perform(recipient.id, type_2, status_1.id, intervals[0])
        subject.perform(recipient.id, type_2, status_2.id, intervals[0])
        
        expect(Notification.all.count).to eq 4
        expect(Notification.where(activity_id: status_1.id, activity_type: "Status", account_id: recipient.id, from_account_id: sender_1.id, count: nil, type: 'favourite_group')).to be_present
        expect(Notification.where(activity_id: status_1.id, activity_type: "Status", account_id: recipient.id, from_account_id: sender_1.id, count: nil, type: 'reblog_group')).to be_present
        expect(Notification.where(activity_id: status_2.id, activity_type: "Status", account_id: recipient.id, from_account_id: sender_2.id, count: nil, type: 'favourite_group')).to be_present
        expect(Notification.where(activity_id: status_2.id, activity_type: "Status", account_id: recipient.id, from_account_id: sender_2.id, count: nil, type: 'reblog_group')).to be_present
      end
    end
  end
end
