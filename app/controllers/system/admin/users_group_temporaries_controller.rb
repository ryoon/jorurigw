class System::Admin::UsersGroupTemporariesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    @current = 'temporary'
    id      = params[:parent] == '0' ? 1 : params[:parent]
    @parent = System::GroupTemporary.new.find(id)
    params[:limit] = nz(params[:limit],30)
    @sort_keys = "user_code ASC"
  end

  def index
#    item = System::UsersGroup.new.readable
    item = System::UsersGroupTemporary.new
    item.group_id = @parent.id
    item.page  params[:page], params[:limit]
    item.order params[:sort], @sort_keys
    @items = item.find(:all)
    _index @items
  end

  def show
    @item = System::UsersGroupTemporary.new.find(params[:id])
    return error_auth unless @item.readable?
    _show @item
  end

end
