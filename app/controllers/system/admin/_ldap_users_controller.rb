class System::Admin::LdapUsersController < ApplicationController
  include System::Controller::Scaffold
  
  def initialize_scaffold
    if params[:parent] == '0'
      @parent = nil
    else
      @parent = params[:parent]
    end
  end
  
  def index
    if @parent
      @items = System::LdapUser.find_users(@parent)
      dump @items[0]
    else
      @items = []
    end
    
    _index @items
  end
  
  def show
  end
end
