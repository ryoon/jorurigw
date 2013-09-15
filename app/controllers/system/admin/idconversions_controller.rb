class System::Admin::IdconversionsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold

    return redirect_to(request.env['PATH_INFO']) if params[:reset]
    _search_condition

#    error_auth unless params[:content]
#    error_auth unless (@content = Cms::Content.find(params[:content]))
  end

  def _search_condition
  end

  def index
    params[:limit] = nz(params[:limit], 10)
    qsa = ['limit', 's_keyword']
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')

    @sort_keys = nz(params[:sort_keys], 'converted_at ASC')
    item = System::Idconversion.new #.readable
#    item.search params
#    item.creator
    item.page   params[:page], nz(params[:limit], 30)
    item.order  params[:id], @sort_keys
    @items = item.find(:all)
    _index @items
  end

  def show
    @item = System::Idconversion.find(params[:id])
    _show @item
  end

  def new
    @item = System::Idconversion.new({
    })
  end

  def create
    @item = System::Idconversion.new(params[:item])
    _create @item
#    _create_a @item
  end
#  def _create_a(item, options = {})
#    respond_to do |format|
#      if item.creatable? && item.save
#        options[:after_process].call if options[:after_process]
#        system_log.add(:item => item, :action => 'create')
#
#        status = params[:_created_status] || :created
#        flash[:notice] = options[:notice] || '登録処理が完了しました'
##        location = url_for(:action => :index)
#        location = "#{Site.current_node.public_uri}"
#        format.html { redirect_to location }
##        format.html { redirect_to url_for(:action => :index) }
#        format.xml  { render :xml => to_xml(item), :status => status, :location => location }
#      else
#        format.html { render :action => "new" }
#        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
#      end
#    end
#  end

  def edit
    if params[:convert]
      @item = System::Idconversion.find(params[:id])
      _rtn = System::Idconversion.convert(params[:convert],@item.tablename)
        respond_to do |format|
          if _rtn == true
            @item.converted_at = Time.now
            if @item.save
              system_log.add(:item => @item, :action => 'update')
              flash[:notice] = '変換処理が成功しました'
              format.html { redirect_to url_for(:action => :index) }
              format.xml  { head :ok }
            else
              flash[:notice] = '変換処理は成功しましたが、結果時刻の保存に失敗しました'
              format.html { render :action => :show }
              format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
            end
          else
            flash[:notice] = '変換処理が失敗しました'
            format.html { render :action => :show }
            format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
          end
        end
    else
      @item = System::Idconversion.find(params[:id])
    end
  end
  def update
    @item = System::Idconversion.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
#    _update_a @item
  end
#  def _update_a(item, options = {})
#    respond_to do |format|
#      if item.editable? && item.save
#        options[:after_process].call if options[:after_process]
#        system_log.add(:item => item, :action => 'update')
#
#        send_recognition_mail(item) if defined?(item.recognizable?) && item.recognizable?
#
#        flash[:notice] = '更新処理が完了しました'
#        location = "#{Site.current_node.public_uri}"
#        format.html { redirect_to location}
##        format.html { redirect_to url_for(:action => :index) }
#        format.xml  { head :ok }
#      else
#        format.html { render :action => :edit }
#        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
#      end
#    end
#  end

  def destroy
    index
#    @item = System::Idconversion.new.find(params[:id])
#    _destroy @item
#    _destroy_a @item
  end
#  def _destroy_a(item, options = {})
#    respond_to do |format|
#      if item.deletable? && item.destroy
#        options[:after_process].call if options[:after_process]
#        system_log.add(:item => item, :action => 'destroy')
#
#        flash[:notice] = options[:notice] || '削除処理が完了しました'
#        location = "#{Site.current_node.public_uri}"
#        format.html { redirect_to location }
##        format.html { redirect_to url_for(:action => :index) }
#        format.xml  { head :ok }
#      else
#        flash[:notice] = '削除できません'
#        format.html { render :action => :show }
#        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
#      end
#    end
#  end

end
