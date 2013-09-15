class Gwqa::Public::QaPreviewsController < ApplicationController

  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Scaffold::Recognition
  include Gwboard::Controller::Scaffold::Publication
  include Gwboard::Controller::Scaffold::Commitment
  include Gwboard::Controller::Authorize

  def initialize_scaffold
    alter_table_name_gwqa
  end


  def index
    item = @qa_doc_table.new
    item.and :state,'<>' ,'public'
    item.page   params[:page], params[:limit]
    item.order  params[:id], "doc_type, latest_updated_at DESC"
    @items = item.find(:all)
    _index @items
  end

  def show
    item = @qa_doc_table.new
    item.and :id, params[:id]
    return http_error(404) unless @item = item.find(:first)

    Page.title = @item.title
    Site.current_item = @item

    @title = @qa_control_table.find_by_id(@item.title_id)
    return error_gwbbs_no_title unless is_authorized(@title)

    _show @item
  end

end
