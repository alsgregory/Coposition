class Api::V1::UsersController < Api::ApiController
  respond_to :json

  before_action :authenticate

  def index
    respond_with User.all.select(:id, :username)
  end

  def show
    @user = User.find(params[:id])
    respond_with @user if @user.approved_developer?(@dev)
  end

  def last_checkin
    @user = User.find(params[:id])
    @device = @user.last_used_device
    @checkin = @user.last_checkin
    respond_with [@device, @checkin] if @user.approved_developer?(@dev)
  end

end