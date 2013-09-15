class Gw::Public::TodosController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    @css = %w(/_common/themes/gw/css/todo.css)
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def init_params
    @s_finished = nz(params[:s_finished],'1')
  end

  def index
    init_params
    item = Gw::Todo.new
    item.page  params[:page], params[:limit]
    cond = Gw::Todo.cond
    cond += case params[:s_finished]
    when "2" # 既読
      ' and coalesce(is_finished, 0) = 1'
    when "3" # 両方
      ''
    else # 未読
      ' and coalesce(is_finished, 0) != 1'
    end

    qsa = %w(s_finished)
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')
    @sort_keys = CGI.unescape(nz(params[:sort_keys], ''))
    sk = @sort_keys
    if /^_title (.+)$/ =~ sk
      sort_title_flg = 1
      sort_title_order = $1
      sk = ''
    end
    order = Gw.join([sk, 'is_finished', "#{Gw.order_last_null :ed_at}"], ',')
    @items = item.find(:all, :conditions => cond, :order => order)
    @items.sort!{|a,b| sort_title_order == 'asc' ? (a._title <=> b._title) : (b._title <=> a._title)} if sort_title_flg
  end

  def show
    init_params
    item = Gw::Todo.new
    @item = item.find(params[:id])
  end

  def new
    init_params
    @item = Gw::Todo.new({})
  end

  def quote
    init_params
    @item = Gw::Todo.new.find(params[:id])
  end

  def create
    init_params
    params[:item] = mobile_params(params[:item]) if request.mobile?
    item = params[:item]
    @item = Gw::Todo.new(item)
    @item.class_id = 1
    @item.uid = Site.user.id
    begin
      @item.ed_at = Gw.date_common(Gw.get_parsed_date(params[:item][:ed_at]))
    rescue
    end
    _create @item, :success_redirect_uri => '/gw/todos/[[id]]', :notice => 'TODOの登録に成功しました'
  end

  def update
    init_params
    @item = Gw::Todo.find(params[:id])
    params[:item] = mobile_params(params[:item]) if request.mobile?
    item = params[:item]
    item[:class_id] = 1
    item[:uid] = Site.user.id
    begin
      item[:ed_at] = Gw.date_common(Gw.get_parsed_date(params[:item][:ed_at]))
    rescue
    end
    @item.attributes = item
    _update @item, :success_redirect_uri => '/gw/todos/[[id]]', :notice => "TODOの更新に成功しました"
  end

  def destroy
    init_params
    @item = Gw::Todo.find(params[:id])
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    _destroy(@item,:success_redirect_uri=>location)
  end

  def setting

  end

  def finish
    @item = Gw::Todo.find(params[:id])
    item = {}
    item[:class_id] = 1
    item[:uid] = Site.user.id
    act = nz(@item.is_finished, 0) != 1
    item[:is_finished] = act ? 1 : nil
    @item.attributes = item
    _update @item, :success_redirect_uri => '/gw/todos', :notice => "TODOを#{act ? '完了する' : '未完了に戻す'}処理に成功しました"
  end

  def confirm
    init_params
    item = Gw::Todo.new
    @item = item.find(params[:id])
  end

  def delete
    init_params
    @item = Gw::Todo.find(params[:id])
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    _destroy(@item,:success_redirect_uri=>location)
  end

  def mobile_params(params)
    ed_at_str = %Q(#{params['ed_at(1i)']}-#{params['ed_at(2i)']}-#{params['ed_at(3i)']})
    params.delete "ed_at(1i)"
    params.delete "ed_at(2i)"
    params.delete "ed_at(3i)"
    params[:ed_at]= ed_at_str
    return params
  end

end
