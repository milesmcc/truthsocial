# frozen_string_literal: true

class DeleteGroupService < BaseService
  include Payloadable

  # The following associations have no important side-effects
  # in callbacks and all of their own associations are secured
  # by foreign keys, making them safe to delete without loading
  # into memory
  ASSOCIATIONS_WITHOUT_SIDE_EFFECTS = %w(
    memberships
    membership_requests
    account_blocks
  )

  ASSOCIATIONS_ON_DESTROY = %w(
  ).freeze

  # Remove a group and remove as much of its data
  # as possible.
  # @param [Group]
  # @param [Hash] options
  def call(group, **options)
    @group = group
    @options = options

    purge_content!
    fulfill_deletion_request!
  end

  private

  def purge_content!
    purge_statuses!
    purge_other_associations!

    @group.destroy
  end

  def purge_statuses!
    @group.statuses.with_discarded.reorder(nil).find_each(&:destroy!)
  end

  def purge_other_associations!
    associations_for_destruction.each do |association_name|
      purge_association(association_name)
    end
  end

  def fulfill_deletion_request!
    @group.deletion_request&.destroy
  end

  def purge_association(association_name)
    association = @group.public_send(association_name)

    if ASSOCIATIONS_WITHOUT_SIDE_EFFECTS.include?(association_name)
      association.in_batches.delete_all
    else
      association.in_batches.destroy_all
    end
  end

  def associations_for_destruction
    ASSOCIATIONS_ON_DESTROY
  end
end
