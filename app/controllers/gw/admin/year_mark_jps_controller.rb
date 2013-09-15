class Gw::Admin::YearMarkJpsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold

    return redirect_to(request.env['PATH_INFO']) if params[:reset]
    _search_condition

  end

  def _search_condition

  end

  def index
    params[:limit] = nz(params[:limit], 10)
    @limit = params[:limit]
    qsa = ['limit', 's_keyword']
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')

    @sort_keys = nz(params[:sort_keys], 'start_at DESC')
    item = Gw::YearMarkJp.new #.readable
    item.search params
    item.page   params[:page], params[:limit]
    item.order  params[:id], @sort_keys
    @items = item.find(:all)
    _index @items
  end

  def show
    @item = Gw::YearMarkJp.find(params[:id])
  end

  def new
    @item = Gw::YearMarkJp.new
  end
  def create
    @item = Gw::YearMarkJp.new(params[:item])
    _create @item
  end

  def edit
    @item = Gw::YearMarkJp.find(params[:id])
  end
  def update
    @item = Gw::YearMarkJp.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def destroy
    @item = Gw::YearMarkJp.new.find(params[:id])
  end

  def csvput
    case params[:csv]
    when 'init'
    when 'put'
        items = Gw::YearMarkJp.find(:all)
        filename = "year_mark_jps_#{params[:nkf]}.csv"
      if items.blank?
      else
        file = Gw::Script::Tool.ar_to_csv(items)
        case params[:nkf]
        when 'utf8'  # UTF8
          send_download "#{filename}", NKF::nkf('-w',file)
        when 'sjis'  # SJIS
          send_download "#{filename}", NKF::nkf('-s',file)
        else
          raise TypeError, 'unknown character set'
        end
      end
    else
      redirect_to gw_year_mark_jps_path
    end
  end

  def csvup
    return if params[:item].nil?
    par_item = params[:item]
    case par_item[:csv]
    when 'up'
      if par_item.nil? || par_item[:nkf].nil? || par_item[:file].nil?
        flash[:notice] = 'ファイル名を入力してください'
      else
        upload_data = par_item[:file]
        f = upload_data.read
        nkf_options = case par_item[:nkf]
        when 'utf8'
          '-w -W'
        when 'sjis'
          '-w -S'
        end
        file =  NKF::nkf(nkf_options,f)
        if file.blank?
        else
          Gw::YearMarkJp.drop_create_table
          s_to = Gw::Script::Tool.import_csv(file, "gw_year_mark_jps")
        end
        redirect_to gw_year_mark_jps_path
      end
    else
      redirect_to gw_year_mark_jps_path
    end

  end
end
