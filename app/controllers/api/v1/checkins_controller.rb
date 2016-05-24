class Api::V1::CheckinsController < Api::ApiController
  respond_to :json

  skip_before_filter :find_user, only: :create
  before_action :device_exists?, only: :create
  before_action :check_user_approved_approvable, :find_device, except: :create

  def index
    if req_from_coposition_app?
      checkins = copo_app_checkins
    else
      params[:per_page].to_i <= 1000 ? per_page = params[:per_page] : per_page = 1000
      checkins = @user.get_checkins(@permissible, @device).paginate(page: params[:page], per_page: per_page)
      paginated_response_headers(checkins)
      checkins = checkins.resolve_address(@permissible, params[:type])
    end
    render json: checkins
  end

  def last
    if req_from_coposition_app?
      checkin = copo_app_checkin
    else
      checkin = @user.get_checkins(@permissible, @device).first
      checkin = checkin.resolve_address(@permissible, params[:type]) if checkin
    end
    checkin ? (render json: [checkin]) : (render json: [])
  end

  def create
    checkin = @device.checkins.create(allowed_params)
    if checkin.save
      @device.notify_subscribers('new_checkin', checkin)
      render json: [checkin]
    else
      render status: 400, json: { message: 'You must provide a lat and lng' }
    end
  end

  private

    def device_exists?
      if (@device = Device.find_by(uuid: request.headers['X-UUID'])).nil?
        render status: 400, json: { message: 'You must provide a valid uuid' }
      end
    end

    def allowed_params
      params.require(:checkin).permit(:lat, :lng, :created_at, :fogged)
    end

    def find_device
      if params[:device_id] then @device = Device.find(params[:device_id]) end
    end

    def copo_app_checkins
      checkins = @device ? @device.checkins : @user.checkins
      checkins = checkins.includes(:device).map do |checkin|
        checkin.reverse_geocode!
      end if params[:type] == 'address'
      checkins
    end

    def copo_app_checkin
      checkins = @device ? @device.checkins : @user.checkins
      if checkins
        checkin = checkins.first
        params[:type] == 'address' ? checkin.reverse_geocode! : checkin
      end
    end
end
