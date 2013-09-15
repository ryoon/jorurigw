class System::Admin::LdapGroupsController < ApplicationController
  include System::Controller::Scaffold
  
  def initialize_scaffold
    if params[:parent] == '0'
      @parent  = nil
      @parents = []
    else
      @parent  = System::LdapGroup.find(:value => params[:parent])
      @parents = @parent.parents
    end
  end
  
  def index
    if !@parent
      @groups = System::LdapGroup.find_one
      @users  = []
    else
      @groups = @parent.children
      @users  = @parent.users
    end
  end
end
