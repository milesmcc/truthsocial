# frozen_string_literal: true

class Api::V1::Truth::Admin::EmailDomainBlocksController < Api::BaseController
  include AccountableConcern

  before_action :require_admin!
  before_action -> { doorkeeper_authorize! :'admin:read' }, only: [:index]
  before_action -> { doorkeeper_authorize! :'admin:write' }, only: [:create, :destroy]
  after_action :set_pagination_headers, only: :index

  DEFAULT_EMAIL_DOMAINS_LIMIT = 20

  def index
    @email_domain_blocks =
      EmailDomainBlock
        .where(parent_id: nil)
        .includes(:children)
        .order(id: :desc)
        .page(params[:page])
        .per(DEFAULT_EMAIL_DOMAINS_LIMIT)

    render json: @email_domain_blocks, each_serializer: REST::Truth::Admin::EmailDomainBlockSerializer
  end

  def create
    @email_domain_block = EmailDomainBlock.create!(domain: params[:domain], with_domain_validation: true)
    log_action :create, @email_domain_block

    render json: @email_domain_block, serializer: REST::Truth::Admin::EmailDomainBlockSerializer
  end

  def destroy
    @email_domain_block = EmailDomainBlock.find(params[:id])
    @email_domain_block.destroy!
    log_action :destroy, @email_domain_block
  end

  private

  def set_pagination_headers
    response.headers['x-page-size'] = DEFAULT_EMAIL_DOMAINS_LIMIT
    response.headers['x-page'] = params[:page] || 1
    response.headers['x-total'] = @email_domain_blocks.size
    response.headers['x-total-pages'] = @email_domain_blocks.total_pages
  end
end
