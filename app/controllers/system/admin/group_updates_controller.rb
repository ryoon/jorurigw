class System::Admin::GroupUpdatesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    @current='updates'

    item = System::GroupChange.new
    item.order "created_at DESC , updated_at DESC"
    @item_latest = item.find(:first)
    rtn = System::GroupChange.check_sequence(@item_latest,'updates')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to system_group_changes_path
        return
    end

    item = System::GroupChange.new
    item.state = '2'
    item.order "created_at DESC , updated_at DESC"
    @item_state2 = item.find(:first)
  end

  def index
    item = System::GroupUpdate.new
    item.order "parent_code ASC , code ASC"
    @items = item.find(:all)
    _index @items
  end

  def show
    @item = System::GroupUpdate.new.find(params[:id])
  end

  def new
    @item = System::GroupUpdate.new
    @item.state = '6'
  end

  def create
    @item = System::GroupUpdate.new(params[:item])
    options={}
    options[:after_process]=Proc.new{
      System::GroupChange.make_record(@item_state2,'updates')
    }
    _create @item,options
  end

  def edit
    @item = System::GroupUpdate.new.find(params[:id])
  end

  def update
    @item = System::GroupUpdate.new.find(params[:id])
    @item.attributes = params[:item]
    options={}
    options[:after_process]=Proc.new{
      System::GroupChange.make_record(@item_state2,'updates')
    }
    _update @item,options
  end

  def destroy
    @item = System::GroupUpdate.new.find(params[:id])
    _destroy @item
  end

  def csv

  end

  def csvup
    require 'fastercsv'
    nkf       = params[:item]['nkf']
    file_path = params[:item]['file']
    if nkf.to_s.blank? or file_path.to_s.blank?
        flash[:notice] = 'ファイル名を入力してください'
        redirect_to :action=>:csv
        return
    end

    upload_data = file_path
    f = upload_data.read
    nkf_options = case nkf
    when 'utf8'
      '-w -W'
    when 'sjis'
      '-w -S'
    end
    file =  NKF::nkf(nkf_options,f)
    if file.blank?
    else
      System::GroupNext.truncate_table
      System::GroupUpdate.truncate_table

      csv = []
      FasterCSV.parse(file) do |row|
        csv.push row
      end

      csv.each_with_index do |x,idx|
        if idx==0
        else
          ar1 = System::GroupUpdate.new
          ar1.parent_code  = x[0]
          ar1.parent_name  = x[1]
          ar1.level_no     = x[2]
          ar1.code         = x[3]
          ar1.name         = x[4]
          ar1.state        = System::GroupUpdate.convert_state(x[5])
          ar1.start_at     = x[6].gsub('/','-')
          ar1.group_id     = 0
          ar1.parent_id    = 0
          ar1.save(false)

          unless ar1.state == '3'

            unless x[7].blank?
              ar2 = System::GroupNext.new
              ar2.group_update_id = ar1.id
              ar2.old_group_id    = 0
              ar2.operation       = System::GroupNext.convert_state(x[7])
              ar2.old_code        = x[8]
              ar2.old_name        = x[9]
              g = System::Group.new
              g.code = x[8]
              g.name = x[9]
              g.order "start_at DESC"
              grp = g.find(:first)
              ar2.old_group_id = grp.id unless grp.blank?
            ar2.save(false)
            end
          end
        end
      end
    end
    System::GroupChange.make_record(@item_state2,'updates')
    redirect_to :action=>:index
  end

end
