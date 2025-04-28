require 'rails_helper'

RSpec.describe GroupFeed, type: :model do
  let(:owner) { Fabricate(:account) }
  let(:group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }
  let!(:owner_member) { Fabricate(:group_membership, group: group, role: :owner, account: owner) }
  let(:member1) { Fabricate(:group_membership, group: group, role: :user).account }
  let(:member2) { Fabricate(:group_membership, group: group, role: :user).account }
  let(:member3) { Fabricate(:group_membership, group: group, role: :user).account }
  let(:user) { Fabricate(:group_membership, group: group, role: :user).account }

  let!(:status1) { Fabricate(:status, account: member1, group: group, visibility: :group) }
  let!(:status2) { Fabricate(:status, account: member2, group: group, visibility: :group) }
  let!(:status3) { Fabricate(:status, account: member3, group: group, visibility: :group) }
  let!(:status4) { Fabricate(:status, account: member1) }
  let!(:status5) { Fabricate(:status, account: member2) }
  let!(:status6) { Fabricate(:status, account: member3) }
  let!(:status7) { Fabricate(:status, account: member1, group: group, visibility: :group) }
  let!(:status8) { Fabricate(:status, account: member2, group: group, visibility: :group) }
  let!(:status9) { Fabricate(:status, account: member3, group: group, visibility: :group) }

  describe '#get' do
    context 'without a logged-in viewer' do
      subject { described_class.new(group, nil) }

      it 'returns group posts in reverse-chronological order' do
        expect(subject.get(10)).to eq [status9, status8, status7, status3, status2, status1]
      end
    end

    context 'with a logged-in viewer' do
      let(:viewer) { Fabricate(:account) }

      subject { described_class.new(group, viewer) }

      before do
        viewer.block!(member2)
      end

      it 'returns group posts in reverse-chronological order, excluding blocked users' do
        expect(subject.get(10)).to eq [status9, status7, status3, status1]
      end

      it 'includes self-statuses' do
        group.memberships.create!(account: viewer, role: :user)
        new_status = Fabricate(:status, group: group, visibility: :group, account: viewer)

        expect(subject.get(10).first).to eq(new_status)
      end

      it 'excludes reblogs' do
        group.memberships.create!(account: viewer, role: :user)
        new_status = Fabricate(:status, group: group, visibility: :group, account: viewer, reblog: status1)

        expect(subject.get(10).first).not_to eq(new_status)
      end

      it 'excludes replies' do
        group.memberships.create!(account: viewer, role: :user)
        new_status = Fabricate(:status, group: group, visibility: :group, account: viewer, in_reply_to_id: status1.id)

        expect(subject.get(10).first).not_to eq(new_status)
      end

      context 'with only_media option present' do
        subject { described_class.new(group, viewer, { only_media: true }) }

        it 'should only return statuses that have media attachments' do
          new_status = Fabricate(:status, group: group, visibility: :group, account: member1)
          MediaAttachment.create(account: Fabricate(:account), file: attachment_fixture('avatar.gif'), status: new_status)

          response = subject.get(10)
          expect(response.size).to eq 1
          expect(response.first).to eq new_status
        end
      end

      context 'if is group user' do
        subject { described_class.new(group, user) }

        before do
          member2.block!(user)
        end

        it 'returns group posts, excluding those from a user blocking you' do
          expect(subject.get(10)).to eq [status9, status7, status3, status1]
        end
      end

      context 'if is group owner' do
        subject { described_class.new(group, owner) }

        before do
          member2.block!(owner)
        end

        it 'returns group posts, including those from a user blocking you' do
          expect(subject.get(10)).to eq [status9, status8, status7, status3, status2, status1]
        end
      end

      context 'if the status is marked with visibility self' do
        let!(:status10) { Fabricate(:status, account: member1, group: group, performed_by_admin: true, visibility: :self) }

        context 'when the author of the status is making the request' do
          subject { described_class.new(group, member1) }

          it 'returns the status for the author' do
            expect(subject.get(10).first.id).to eq status10.id
          end
        end

        context 'when any other user is making the request' do
          subject { described_class.new(group, member2) }

          it 'does not return the status for other users' do
            expect(subject.get(10).first.id).not_to eq [status10.id]
          end
        end
      end
    end
  end
end
