module System::Controller::Admin::Log
  def system_log
    params = {}
    params[:user_id]    = Site.user.id
    params[:controller] = self.class.to_s
    return System::AdminLog.new(params)
  end
end