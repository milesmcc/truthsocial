namespace :groups do
  desc 'Generates groups and relation data'
  # Run: rails groups:setup
  task setup: :environment do
    groups = []
    tags = Faker::Lorem.words(number: 10)

    # Create groups
    5.times do
      group = Group.new(display_name: Faker::Lorem.characters(number: 15), note: Faker::Lorem.characters(number: 30), statuses_visibility: %w(everyone members_only).sample)
      groups << group
    end

    groups.each do |group|
      owner = create_group_account
      owner.save(validate: false)
      group.owner_account = owner
      group.save!
      group.memberships.create!(account: owner, role: :owner) unless group.memberships.where(role: :owner).exists?
      rand(1..5).times do # create membership_requests
        requester = create_group_account
        requester.save(validate: false)
        group.membership_requests.create!(account: requester)
      end
      rand(1..10).times do # create memberships, tags and statuses for group
        member = create_group_account
        member.save(validate: false)
        group.memberships.create!(account: member, role: [:user, :admin].sample)

        next if group.tags.count > 3
        tags.sample(rand(1..3)).each do |tag_name|
          Tag.find_or_create_by_names(tag_name) do |tag|
            tag_exist = group.tags.find_by(name: tag.name)
            group.tags << tag unless tag_exist
            rand(1..10).times do
              status = PostStatusService.new.call(member,
                                                  text: "#{Faker::Lorem.sentence} ##{tag.name}",
                                                  group: group,
                                                  visibility: 'group')
              status.update!(created_at: rand(1..10).days.ago)
            end
          end
        end
      end
      GroupSuggestion.find_or_create_by!(group: group)
    end

    Procedure.refresh_trending_groups
    Procedure.refresh_group_tag_use_cache
    Procedure.refresh_tag_use_cache
  end

  # Run: rake 'groups:statuses' <group_id> <number of statuses>
  task statuses: :environment do
    group = Group.find(ARGV[1])
    ARGV[2].to_i.times do
      Status.create!(account: group.members.sample, visibility: 'group', group_id: group.id, text: Faker::Lorem.sentence)
    end

    exit
  end

  def create_group_account
    name = Faker::Internet.unique.user_name(separators: ['_']) + rand(1..100_000).to_s
    user = Fabricate.create(:user, email: "#{name}@example.com", password: 'truthsocial') do
      account { Fabricate(:account, username: name) }
    end

    user.account
  end
end
