class Api::Mock::FeedsController < Api::BaseController
  def index
    output = []

    15.times do
      output.push(Documentation::Entities::Feed.new.object)
    end

    render json: output
  end

  def create
    render json: Documentation::Entities::Feed.new(params[:name], params[:description], params[:visibility]).object
  end

  def show
    render json: Documentation::Entities::Feed.new(params[:id]).object
  end

  def update
    render json: Documentation::Entities::Feed.new(params[:id]).object
  end

  def destroy
    render json: {}, status: 204
  end

  def sort
    output = []

    15.times do
      output.push(Documentation::Entities::Feed.new.object)
    end

    render json: output
  end

  def add_account
    render json: {}, status: 204
  end

  def remove_account
    render json: {}, status: 204
  end

  def unmute_group
    render json: {}, status: 204
  end

  def mute_group
    render json: {}, status: 204
  end
end