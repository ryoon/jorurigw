class System::Public::AccountController < System::Admin::AccountController
  protect_from_forgery :except => :login

  def login
    login_common :public
  end
  def logout
    logout_common :public
  end
end
