class Gw::Public::NotesController < ApplicationController
  include System::Controller::Scaffold

  def create
    @item = Gw::Note.new(params[:new_item]) rescue nil
    return http_error(404) if @item.blank? || @item.uid != Site.user.id
    location = "/ind_portal"
    if @item.creatable? && @item.save
      respond_to do |format|
        format.html { redirect_to location }
        format.xml  { render :xml => to_xml(@item), :status => status, :location => location }
      end
    else
      flash[:note_new_error_item] = @item
      respond_to do |format|
        format.html { redirect_to location }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @item = Gw::Note.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.uid != Site.user.id
    @item.attributes = params[:edit_item]
    location = "/ind_portal"
    if @item.editable? && @item.save
      respond_to do |format|
        format.html { redirect_to location }
        format.xml  { head :ok }
      end
    else
      flash[:note_edit_error_item] = @item
      respond_to do |format|
        format.html { redirect_to location }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @item = Gw::Note.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.uid != Site.user.id
    _destroy(@item, :success_redirect_uri => "/ind_portal", :notice => "")
  end

  def edit_props
    props = Gw::Note.read_props
    params['display_schedule'] = props['display_schedule']
  end

  def save_props
    props = {}
    props['display_schedule'] = params[:item][:display_schedule]
    Gw::Note.save_props(props)
    redirect_to '/ind_portal'
  end

  def fill_data
    text = Gw::Note.get_data_by_json(params[:id])
    respond_to do |format|
      format.csv { render :text => text, :layout=>false, :locals=>{:f=>@item} }
    end
  end

  def move_higher
    Gw::Note.find(params[:id]).move_higher rescue nil
    redirect_to '/ind_portal'
  end

  def move_lower
    Gw::Note.find(params[:id]).move_lower rescue nil
    redirect_to '/ind_portal'
  end
end