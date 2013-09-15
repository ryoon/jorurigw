class System::Admin::GroupHistoryTemporariesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    @current = 'history'
    @action = params[:action]

    count = System::GroupHistoryTemporary.count(:all)
    if count < 1
      flash[:notice] = '確認対象のデータは削除されています。'
      location  = system_group_changes_path
      return redirect_to(location)
    end

    id      = nz(params[:id],1)
    @group  = System::GroupHistoryTemporary.find_by_id(id)
    if @group.blank?
      flash[:notice] = '確認対象のデータは削除されています。'
      location  = system_group_changes_path
      return redirect_to(location)
    end

    if @group.level_no==2
      params[:p_id] = id
    else
      if @group.level_no==3
        params[:p_id] = @group.parent_id
      end
    end
    @p      = nz(params[:p_id],1)
    if @p.to_i==0
      @p=1
    end
    @root   = System::GroupHistoryTemporary.find_by_id(1)
    @parent = System::GroupHistoryTemporary.find_by_id(@p)

    @limit  = nz(params[:limit],300)
  end

  def index
    search_p_id = nz(params[:p_id],0)
    if  search_p_id == 0
      @group  = @root
    else
      @parent = System::GroupHistoryTemporary.find_by_id(search_p_id)
      if @parent.blank?
        @group  = @root
        @parent = @root
      else
        @group  = @parent
        @p_id   = search_p_id
      end
    end

      current_date = Date.today
      next_date = current_date >> 1
      start_date = next_date.year.to_s + '-' + next_date.month.to_s + '-1'

      if @group.level_no==1
        item = System::GroupHistoryTemporary.new
        item.and 'sql',"level_no  = 2"
        item.and 'sql'," state = 'enabled'"
        item.and 'sql',%Q( end_at is null or end_at >= '#{start_date}')
        item.search params
        item.order params[:sort], :code
        @items = item.find(:all)
      else

        item = System::GroupHistoryTemporary.new
        item.and 'sql',"level_no  = 3"
        item.and 'sql'," state = 'enabled'"
        item.and 'sql'," parent_id = #{@p_id}"
        item.and 'sql',%Q( end_at is null or end_at >= '#{start_date}')
        item.search params
        item.order params[:sort], :code
        @items = item.find(:all)
      end
  end

  def show
    @item = System::GroupHistoryTemporary.find_by_id(params[:id])
    return error_auth unless @item.readable?
    @parent = @item.parent  if @parent.level_no > 1
    @parent = @item         if @parent.level_no == 1
    _show @item
  end

end