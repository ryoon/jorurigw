class Gwsub::Public::Sb01::Sb01TrainingEntriesController < ApplicationController
  include System::Controller::Scaffold
  include Gwboard::Controller::SortKey
  include Gwbbs::Model::DbnameAlias
  include Gwboard::Controller::Authorize

  def initialize_scaffold

    return redirect_to(request.env['PATH_INFO']) if params[:reset]

#    error_auth unless params[:content]
#    error_auth unless (@content = Cms::Content.find(params[:content]))
  end

  def index
    init_params
    @l2_current=nz(params[:l2_c],'01')
    today = Time.now.strftime("%Y-%m-%d %H:%M")
    item = Gwsub::Sb01TrainingSchedule.new
    item.page   params[:page], params[:limit]
    @items = item.find(:all,
      :select => 'gwsub_sb01_training_schedules.*, min(gwsub_sb01_training_schedules.from_start)',
      :include => [:training],
      #:conditions => "gwsub_sb01_training_schedules.state = 2 and from_start >= '#{today}'",
      :conditions => "gwsub_sb01_training_schedules.state != 1 and from_start >= '#{today}'",
      :group => "training_id",
      :order => 'min(gwsub_sb01_training_schedules.from_start), gwsub_sb01_trainings.title'
    )
    _index @items
  end

  def index_date
    init_params
    @l2_current=nz(params[:l2_c],'02')
    today = Time.now.strftime("%Y-%m-%d %H:%M")
    item = Gwsub::Sb01TrainingSchedule.new
    item.page   params[:page], params[:limit]
    if params[:sort_keys]
      @items = item.find(:all,
      :include => [:training],
      #:conditions => "gwsub_sb01_training_schedules.state = 2 and from_start >= '#{today}'",
      :conditions => "gwsub_sb01_training_schedules.state != 1",
      :order => @sort_keys
    )
    else
      #sub = "SELECT training_id,min(from_start) as min_date FROM gwsub_sb01_training_schedules WHERE state = 2 and from_start >= '#{today}' GROUP BY training_id "
      sub = "SELECT training_id,min(from_start) as min_date FROM gwsub_sb01_training_schedules WHERE state != 1 and from_start >= '#{today}' GROUP BY training_id "
      from = "gwsub_sb01_training_schedules LEFT JOIN (#{sub}) AS ts ON ts.training_id = gwsub_sb01_training_schedules.training_id"
      @items = item.find(:all,
        :from => from,
        :include => [:training],
        :select => "gwsub_sb01_training_schedules.*, ts.min_date, gwsub_sb01_trainings.title",
        #:conditions => "gwsub_sb01_training_schedules.state = 2 and gwsub_sb01_training_schedules.from_start >= '#{today}'",
        :conditions => "gwsub_sb01_training_schedules.state != 1 and from_start >= '#{today}'",
        :order => "ts.min_date, gwsub_sb01_trainings.title, gwsub_sb01_training_schedules.from_start"
      )
    end
    _index @items
  end

  def show
    init_params
    #today = Time.now.strftime("%Y-%m-%d %H:%M")
    @item = Gwsub::Sb01Training.find(params[:id])
    #@ts  = Gwsub::Sb01TrainingSchedule.find(:all, :conditions => ["training_id = ? and state = 2 and from_start >= '#{today}'",@item.id ],:order => :from_start)
    @ts  = Gwsub::Sb01TrainingSchedule.find(:all, :conditions => ["training_id = ? and state != 1",@item.id ],:order => :from_start)
  end

  def init_params
    # ユーザー権限設定
    @role_developer  = Gwsub::Sb01Training.is_dev?(Site.user.id)
    @role_admin      = Gwsub::Sb01Training.is_admin?(Site.user.id)
    @u_role = @role_developer || @role_admin

    # 表示行数　設定
    @limits = nz(params[:limit],30)
    # 掲示板分類
    # catgories : 掲示板分類（1:研修一覧・2:受講者向け利用方法・3:企画者向け利用方法）
    @cat = '1'
    @menu_title = "検索・申込"
    # 表示形式
    @v = nz(params[:v],'1')

    @bbs_link_title  = '別ウィンドウ・別タブで案内記事を開きます'

    search_condition
    sortkeys_setting
    @css = %w(/_common/themes/gw/css/gwsub.css)
    @l1_current=nz(params[:l1_c],'01')
    @l2_current=nz(params[:l2_c],'01')
    case @v.to_i
    when 1
      @l2_current=nz(params[:l2_c],'01')
    when 2
      @l2_current=nz(params[:l2_c],'01')
    when 3
      @l2_current=nz(params[:l2_c],'03')
    else
      @l2_current=nil
    end
#pp params
  end

  def search_condition
    params[:l1_c]   = nz(params[:l1_c],@l1_current)
    params[:l2_c]   = nz(params[:l2_c],@l2_current)
    params[:cat]    = nz(params[:cat],@cat)
    params[:limit]  = nz(params[:limit], @limits)

    qsa = ['limit' , 's_keyword' , 'cat' ,'g_id']
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')
  end
  def sortkeys_setting
     @sort_keys = nz(params[:sort_keys], 'from_start, gwsub_sb01_trainings.title' )
#    @sort_keys = nz(params[:sort_keys], 'fyear_markjp DESC , categories ASC , bbs_url ASC' )
  end
end
