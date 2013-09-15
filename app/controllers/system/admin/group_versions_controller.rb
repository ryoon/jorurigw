class System::Admin::GroupVersionsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
  end

  def index
    params[:limit] = nz(params[:limit], 10)
    qsa = ['limit', 's_keyword']
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')
    @sort_keys = nz(params[:sort_keys], 'start_at DESC')

    item = System::GroupVersion.new #.readable

    item.page   params[:page], nz(params[:limit], 10)
    item.order  params[:id], @sort_keys
    @items = item.find(:all)
    _index @items
  end

  def show
    @item = System::GroupVersion.find(params[:id])
    _show @item
  end

  def new
    @item = System::GroupVersion.new
  end
  def create
    @item = System::GroupVersion.new(params[:item])
    _create_a @item
  end
  def _create_a(item, options = {})
    respond_to do |format|
      if item.save
        options[:after_process].call if options[:after_process]
        system_log.add(:item => item, :action => 'create')

        status = params[:_created_status] || :created
        flash[:notice] = options[:notice] || '登録処理が完了しました'

        format.html { redirect_to url_for(:action => :index) }
        format.xml  { render :xml => to_xml(item), :status => status, :location => location }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @item = System::GroupVersion.find(params[:id])
  end

  def update
    @item = System::GroupVersion.new.find(params[:id])
    @item.attributes = params[:item]
    _update_a @item
  end

  def _update_a(item, options = {})
    respond_to do |format|
      if item.save
        options[:after_process].call if options[:after_process]
        system_log.add(:item => item, :action => 'update')

        flash[:notice] = '更新処理が完了しました'

        format.html { redirect_to url_for(:action => :index) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @item = System::GroupVersion.find(params[:id])
    _destroy_a @item
  end

  def _destroy_a(item, options = {})
    respond_to do |format|
      if item.destroy
        options[:after_process].call if options[:after_process]
        system_log.add(:item => item, :action => 'destroy')

        flash[:notice] = options[:notice] || '削除処理が完了しました'
        format.html { redirect_to url_for(:action => :index) }
        format.xml  { head :ok }
      else
        flash[:notice] = '削除できません'
        format.html { render :action => :show }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def item_to_xml(item, options = {})
    options[:include] = [:status]
    xml = ''; xml << item.to_xml(options) do |n|
      #n << item.relation.to_xml(:root => 'relations', :skip_instruct => true, :include => [:user]) if item.relation
    end
    return xml
  end

end
