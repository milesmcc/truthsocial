class UpdateGroupService
  attr_accessor :group, :group_params, :tag_params

  def initialize(group, group_params, tag_params)
    @group = group
    @group_params = group_params
    @tag_params = tag_params
  end

  def call
    if tag_params.present?
      if tag_params.join.present?
        tags = []

        Tag.find_or_create_by_names(tag_params) do |tag|
          raise Mastodon::ValidationError, I18n.t('groups.errors.invalid_group_tag') unless tag.valid?

          tags << tag
        end

        current_hidden_tags = group.tags.where(group_tags: { group_tag_type: :hidden })
        group.tags = current_hidden_tags + tags
      else
        GroupTag.where(group_id: @group.id, group_tag_type: :pinned)&.destroy_all
      end
    end

    if group_params[:owner_account_id].present?
      ApplicationRecord.transaction do
        group.memberships.find_by!(account: group.owner_account_id).update!(role: group_params[:previous_owner_role] || :user)
        group.memberships.find_by!(account_id: group_params[:owner_account_id]).update!(role: :owner)
      end
    end

    group.update!(group_params.except(:previous_owner_role))
    clear_avatar if group_params[:avatar]&.blank?
    clear_header if group_params[:header]&.blank?
    group.save! if group.changed?
  end

  private

  def clear_avatar
    group.avatar_file_name = nil
    group.avatar_content_type = nil
    group.avatar_file_size = nil
  end

  def clear_header
    group.header_file_name = nil
    group.header_content_type = nil
    group.header_file_size = nil
  end
end
