class Gw::Public::PropOtherLimitsController < Gw::Public::PropGenreCommonController

  def initialize_scaffold
    @css = %w(/_common/themes/gw/css/prop_extra/schedule.css)
  end

  def index
    return authentication_error(403) unless Gw::PropOtherLimit.is_admin?(Site.user.id)==true

    item = Gw::PropOtherLimit.new
    item.page   params[:page], 20
    item.order  "id"
    @items = item.find(:all, :conditions => "state = 'enabled'", :order => "sort_no")
  end

  def show
    return authentication_error(403) unless Gw::PropOtherLimit.is_admin?(Site.user.id)==true
    @item = Gw::PropOtherLimit.new.find(params[:id])
  end

  def new
    return authentication_error(403) unless Gw::PropOtherLimit.is_admin?(Site.user.id)==true

    flash[:notice] = "新規登録はできません。"
    location = "Gw.chop_with(#{Site.current_node.public_uri},'/')"
    redirect_to location
    return

end

  def create
    return authentication_error(403) unless Gw::PropOtherLimit.is_admin?(Site.user.id)==true

    @item = Gw::PropOtherLimit.new.find(params[:id])
    @item.attributes = params[:item]

    location = "Gw.chop_with(#{Site.current_node.public_uri},'/')"
    options = {
      :success_redirect_uri=>location}
    _update @item,options
  end

  def edit
    return authentication_error(403) unless Gw::PropOtherLimit.is_admin?(Site.user.id)==true

    @item = Gw::PropOtherLimit.new.find(params[:id])
  end

  def update
    return authentication_error(403) unless Gw::PropOtherLimit.is_admin?(Site.user.id)==true

    @item = Gw::PropOtherLimit.new.find(params[:id])
    @item.attributes = params[:item]

    location = "#{Site.current_node.public_uri}#{params[:id]}"
    options = {
      :success_redirect_uri=>location}
    _update @item,options
  end

  def destroy
    return authentication_error(403) unless Gw::PropOtherLimit.is_admin?(Site.user.id)==true

    @item = Gw::PropOtherLimit.find(params[:id])
    location = "#{Site.current_node.public_uri}"
    options = {
      :success_redirect_uri=>location}
    _destroy(@item,options)
  end

  def synchro
    return authentication_error(403) unless Gw::PropOtherLimit.is_admin?(Site.user.id)==true

    items = Gw::PropOtherLimit.update_all("state = 'disabled'")
    groups = System::Group.find(:all, :conditions => "state = 'enabled' and level_no = 3", :order => "sort_no")

    groups.each { |group|
      _model = Gw::PropOtherLimit.find_by_gid(group.id)
      if _model.blank?
        _model = Gw::PropOtherLimit.new
        _model.state = "enabled"
        _model.gid = group.id
        _model.sort_no = group.sort_no
        _model.limit = 20
      else
        _model.state = "enabled"
        _model.sort_no = group.sort_no
      end
      _model.save!
    }
    flash[:notice] = "同期処理は終了しました。"
    redirect_to "/gw/prop_other_limits/"
  end

end
