module System::Controller::Public::Log
  def system_log
    params = {}
    params[:user_id]    = Site.user.id
    params[:controller] = self.class.to_s
    return System::PublicLog.new(params)
  end
end