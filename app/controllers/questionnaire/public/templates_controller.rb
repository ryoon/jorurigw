################################################################################
#テンプレート基本情報登録
################################################################################
class Questionnaire::Public::TemplatesController < ApplicationController
  include System::Controller::Scaffold
  include Questionnaire::Model::Database
  include Questionnaire::Model::TemplateSystemname

  def initialize_scaffold
    @css = ["/_common/themes/gw/css/circular.css"]
    @system_title = 'アンケート　テンプレート'
    @system_path = "/#{self.system_name}"
    params[:cond] = "template"
  end

  def index
    system_admin_flags

    if @is_sysadm
      index_admin
    else
      index_normal
    end
    _index @items
  end

  def index_admin
    item = Questionnaire::TemplateBase.new
    item.page(params[:page], params[:limit])
    @items = item.find(:all, :order=>'expiry_date DESC, id DESC')
  end

  def index_normal
    item = Questionnaire::TemplateBase.new
    item.and :state ,'public'
    item.and "sql", "admin_setting = 1 OR (admin_setting = 0 AND createrdivision_id = '#{Site.user_group.code}')"
    item.page(params[:page], params[:limit])
    @items = item.find(:all, :order=>'expiry_date DESC, id DESC')
  end
  def new
    system_admin_flags
    #return authentication_error(403) unless @is_sysadm

    @item = Questionnaire::TemplateBase.new({
      :state => 'draft',
      :section_code => Site.user_group.code ,
      :send_change => '1',  #配信先は所属
      :spec_config => 3 ,   #他の回答者名を表示する
      :manage_title => '',
      :title => '',
      :able_date => Time.now.strftime("%Y-%m-%d"),
      :expiry_date => 7.days.since.strftime("%Y-%m-%d %H:00"),
      :default_limit => 100,
      :admin_setting => 1
    })
  end

  def create
    system_admin_flags
    #return authentication_error(403) unless @is_sysadm

    @item = Questionnaire::TemplateBase.new(params[:item])

    @item.able_date = Time.now.strftime("%Y-%m-%d")
    @item.section_code = Site.user_group.code
    @item.createdate = Time.now.strftime("%Y-%m-%d %H:%M")
    @item.creater_id = Site.user.code
    @item.creater = Site.user.name
    @item.createrdivision = Site.user_group.name
    @item.createrdivision_id = Site.user_group.code

    _self_create(@item)
  end

  def show
    system_admin_flags
    #return authentication_error(403) unless @is_sysadm

    @item = Questionnaire::TemplateBase.find_by_id(params[:id])
    return http_error(404) unless @item

    item = Questionnaire::FormField.new
    item.and :parent_id, @item.id
    item.page params[:page], params[:limit]
    @fields = item.find(:all)
    _show @item
  end

  def edit
    system_admin_flags
    #return authentication_error(403) unless @is_sysadm

    @item = Questionnaire::TemplateBase.find_by_id(params[:id])
    return http_error(404) unless @item
  end

  #
  def update
    system_admin_flags
    #return authentication_error(403) unless @is_sysadm

    @item = Questionnaire::TemplateBase.find_by_id(params[:id])
    return http_error(404) unless @item

    @before_state = @item.state

    @item.attributes = params[:item]

    @item.state = 'closed' if @before_state == 'closed'
    @item._commission_state = @before_state
    @item.section_code = Site.user_group.code
    @item.editdate = Time.now.strftime("%Y-%m-%d %H:%M")
    @item.editor_id = Site.user.code
    @item.editor = Site.user.name
    @item.editordivision = Site.user_group.name
    @item.editordivision_id = Site.user_group.code

    location = Site.current_node.public_uri
    _update(@item, :success_redirect_uri=>location)
  end
  #
  def destroy
    system_admin_flags
    #return authentication_error(403) unless @is_sysadm

    @item = Questionnaire::TemplateBase.find_by_id(params[:id])
    return http_error(404) unless @item

    location = Site.current_node.public_uri
    _destroy(@item, :success_redirect_uri=>location)
  end

  def _self_create(item, options = {})
    respond_to do |format|
      validation = nz(options[:validation], true)
      if item.creatable? && item.save(validation)
        options[:after_process].call if options[:after_process]
        system_log.add(:item => item, :action => 'create')
        location = item.show_path
        status = params[:_created_status] || :created
        flash[:notice] = options[:notice] || '登録処理が完了しました'
        format.html { redirect_to location }
        format.xml  { render :xml => to_xml(item), :status => status, :location => location }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def open
    item = Questionnaire::TemplateBase.find_by_id(params[:id])
    item.state = "public"
    item.save(false)
    location = "/questionnaire/templates"
    return redirect_to location
  end
  def close
    item = Questionnaire::TemplateBase.find_by_id(params[:id])
    item.state = "draft"
    item.save(false)
    location = "/questionnaire/templates"
    return redirect_to location
  end
end