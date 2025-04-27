# frozen_string_literal: true

require 'rails_helper'

describe REST::StatusSerializer do
	let!(:account) { Fabricate(:account) }
	let!(:user) { Fabricate(:user) }
	let!(:parent_with_self_visibility)  { Fabricate(:status, account: account, visibility: :self) }
	let!(:parent)  { Fabricate(:status, account: account, visibility: :public) }
	let!(:reply)  { Fabricate(:status, account: account, thread: parent, visibility: :public) }
	let!(:reply_to_self_visibility)  { Fabricate(:status, account: account, thread: parent_with_self_visibility, visibility: :public) }
	let!(:nested_reply)  { Fabricate(:status, account: account, thread: reply, visibility: :public) }

	subject { JSON.parse(@serialization.to_json) }

  context 'when it is an original status' do
		before(:each) do
			@serialization = ActiveModelSerializers::SerializableResource.new(parent, serializer: REST::StatusSerializer, scope: user, scope_name: :current_user)
		end

		it 'returns an ID' do
			expect(subject['id'].to_i).to eq(parent.id)
		end

		it 'returns an empty In Reply To object' do
			expect(subject['in_reply_to']).to eq(nil)
		end
	end

	context 'when it is a reply' do
		before(:each) do
			@serialization = ActiveModelSerializers::SerializableResource.new(reply, serializer: REST::StatusSerializer, scope: user, scope_name: :current_user)
		end

		it 'returns an In Reply To object' do
			expect(subject['in_reply_to']).to be_a Hash
		end

		describe '#in_reply_to' do
			before(:each) do
				@object = subject['in_reply_to']
			end

			it 'returns parent ID' do
				expect(@object['id'].to_i).to eq(parent.id)
			end

			it 'returns parent content' do
				expect(@object['content']).to eq('<p>' + parent.content + '</p>')
			end

			it 'returns parent account object' do
				expect(@object['account']['id'].to_i).to eq(parent.account_id)
			end
		end
	end

	context 'when it is a nested reply' do
		before(:each) do
			@serialization = ActiveModelSerializers::SerializableResource.new(nested_reply, serializer: REST::StatusSerializer, scope: user, scope_name: :current_user)
		end

		it 'returns only one level of in_reply_to' do
			expect(subject['in_reply_to']).to be_a Hash
			expect(subject['in_reply_to']['in_reply_to']).to be_nil
		end
	end



	context 'when it is a reply and exclude parameter is passed' do
		before(:each) do
			@serialization = ActiveModelSerializers::SerializableResource.new(reply, serializer: REST::StatusSerializer, scope: user, scope_name: :current_user, exclude_reply_previews: true)
		end

		it 'returns an empty In Reply To object' do
			expect(subject['in_reply_to']).to eq(nil)
		end
	end

	context 'when a parent quote truth is marked as self' do
		before(:each) do
			@serialization = ActiveModelSerializers::SerializableResource.new(reply_to_self_visibility, serializer: REST::StatusSerializer, scope: user, scope_name: :current_user)
		end

		it 'returns an empty In Reply To object' do
			expect(subject['in_reply_to']).to eq(nil)
		end
	end


end
