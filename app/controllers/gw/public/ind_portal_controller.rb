class Gw::Public::IndPortalController < ApplicationController

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def init_params
    @items = Gw::IndPortalPiece.get_user_items
    @items = @items.select { |x| x.position == 'main' }
    @setting = Gw::IndPortalSetting.read
    @usables = Gw::IndPortalPiece.get_usable_items
    @usables = @usables.select { |x| x.position == 'main' }
  end

  def index
    init_params
  end

  def new
    init_params
  end

  def setting
    init_params
    render :text=>'<span class="mock">モックです。</span>'
  end

  def add
    init_params
    id = params[:id].to_i
    genre = params[:genre]
    raise "入力が不正です" if id.blank? || genre.blank?
    hu = HashWithIndifferentAccess.new({'portals' => {}})
    add_cands = Gw::Model::Schedule.get_ind_portal_add_cands_all
    add_cand = add_cands.select{|x| "#{x[0]}"=="#{id}" && x[2] == genre}
    if add_cand.length > 0
      x = add_cand[0]
      add_h = { 'title'=>x[1] }
      add_h['sort_no'] = nz(@pieces_raw.collect{|y| y['sort_no']}.max,0)+1
      add_h['piece_name'] = case x[2]
      when 'gwbbs'
        "piece/gw-bbs-mock #{x[2]}_#{x[0]}_15"
      else
        "piece/gw-#{x[2]} #{x[0]}"
      end
      @pieces_raw.push add_h
    end
    @pieces_raw.each{|x|
      hu['portals'][x['sort_no']] = x
    }
    ret = Gw::Model::UserProperty.save('portal', hu)
    redirect_to '/ind_portal/new'
  end

  def up
    updown params, -1
  end

  def down
    updown params, 1
  end

  def destroy
    init_params
    id = params[:id].to_i
    hu = {'portals' => {}}
    @pieces_raw.reject{|x| x['sort_no'] == id}.each{|x|
      hu['portals'][x['sort_no']] = x
    }
    ret = Gw::Model::UserProperty.save('portal', hu)
    redirect_to '/ind_portal/new'
  end

private
  def updown(params, inc)
    init_params
    id = params[:id].to_i
    id_rep = id + inc
    hu = {'portals' => {}}
    @pieces_raw.each{|x|
      case
      when x['sort_no'] == id
        x['sort_no'] = id_rep
      when x['sort_no'] == id_rep
        x['sort_no'] = id
      end
      hu['portals'][x['sort_no']] = x
    } if @pieces_raw.select{|x|x['sort_no'] == id}.length > 0 && @pieces_raw.select{|x|x['sort_no'] == id_rep}.length > 0
    ret = Gw::Model::UserProperty.save('portal', hu)
    redirect_to '/ind_portal/new'
  end
end
