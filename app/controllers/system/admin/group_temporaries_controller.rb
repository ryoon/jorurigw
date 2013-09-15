class System::Admin::GroupTemporariesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    @current = 'temporary'
    @action = params[:action]

    count = System::GroupTemporary.count(:all)
    if count < 1
      location  = system_group_changes_path
      flash[:notice] = '確認対象のデータは削除されています。'
      return redirect_to(location)
    end

    id      = params[:parent] == '0' ? 1 : params[:parent]
    @parent = System::GroupTemporary.new.find(id)
  end

  def index
    item = System::GroupTemporary.new #.readable
    item.parent_id = @parent.id
    item.state = 'enabled'
    item.page  params[:page], params[:limit]
    item.order params[:sort], :code
    @items = item.find(:all)
    _index @items
  end
  def show
    @item = System::GroupTemporary.new.find(params[:id])
    return error_auth unless @item.readable?
    _show @item
  end
end
