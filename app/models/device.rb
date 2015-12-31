class Device < ActiveRecord::Base
  include SlackNotifiable

  belongs_to :user
  has_many :checkins
  has_many :device_developer_privileges
  has_many :developers, through: :device_developer_privileges

  before_create do |dev|
    dev.uuid = SecureRandom.uuid
  end

  def checkins
    delayed? ? super.where("created_at < ?", delayed.minutes.ago) : super
  end


  def switch_fog
    self.fogged = !self.fogged
    save
    self.fogged
  end

  def privilege_for(dev)
    device_developer_privileges.find_by(developer: dev).privilege
  end

  def reverse_privilege_for(dev)
    if privilege_for(dev) == "complete"
      "disallowed"
    else
      "complete"
    end
  end

  def create_checkin(lat:, lng:)
    checkins << Checkin.create(uuid: uuid, lat: lat, lng: lng)
  end

  def change_privilege_for(dev, new_privilege)
    if dev.respond_to? :id
      dev = dev.id
    end
    record = device_developer_privileges.find_by(developer: dev)
    record.privilege = new_privilege
    record.save
  end

  def device_checkin_hash
    hash = as_json
    hash[:last_checkin] = checkins.last.get_data if checkins.exists?
    hash
  end

  def slack_message
    "A new device has been created"
  end

  ###########

  ## Metadata ##

  def checkins_over(param, range)
    checkins.where("extract( #{param} from created_at) IN (?)", range)
  end

  def most_frequent_coords(checkins = self.checkins)
    lat = checkins.group(:lat).count.max_by{|k,v| v}[0]
    lng = checkins.group(:lng).count.max_by{|k,v| v}[0]
    return lat,lng
  end

  def most_frequent_coords_over(param, range)
    most_frequent_coords(checkins_over(param, range))
  end

  def recent_checkins(range)
    today = Date.today
    past = today - range
    checkins.where(["created_at >= ? and created_at <= ?", past.beginning_of_day, today.end_of_day])
  end

  def recent_cities_coords(range)
    lat, lng = most_frequent_coords
    recent_checks = recent_checkins(7)
    checks = recent_checks.where("(lat - ?).abs > 1 OR (lng - ?).abs > 1", lat, lng).select("DISTINCT lat,lng")
    cities_coords = checks.map do |check|
      [check.lat, check.lng]
    end
  end

  # Probably too complicated for actual use, returns first coords found for a specific hour on a specific date.
  def location_at(day_v, month_v, year_v, hour_v)
    checks = checkins.where('extract (day from created_at) = ? AND extract(month from created_at) = ? AND extract(year from created_at) = ? AND extract(hour from created_at) = ?', day_v, month_v, year_v, hour_v)
    if checks.exists?
      checks.each do |checkin|
        return checkin.lat unless checkin.lat.nil?
      end
      return "No address for checkins at this date"
    end
    return "No Checkins at date"
  end



end