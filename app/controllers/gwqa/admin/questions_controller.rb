class Gwqa::Admin::QuestionsController < ApplicationController

  include System::Controller::Scaffold
  include System::Controller::Scaffold::Recognition
  include System::Controller::Scaffold::Publication
  include System::Controller::Scaffold::Commitment

  def index
    @title = Gwqa::Control.find_by_id(params[:parent])
    return error_auth unless @title

    item = Gwqa::Doc.new
    item.and :doc_type, 0
    item.and :title_id, params[:parent]
    item.search params
    item.page   params[:page], params[:limit]
    item.order  params[:id], "id"
    @items = item.find(:all)
    _index @items
  end

  def show
    @title = Gwqa::Control.find_by_id(params[:parent])
    return error_auth unless @title

    item = Gwqa::Doc.new
    item.and :doc_type, 0
    item.and :title_id, params[:parent]
    @item = item.find(params[:id])
    _show @item
  end

  def edit
    @title = Gwqa::Control.find_by_id(params[:parent])
    return error_auth unless @title

    item = Gwqa::Doc.new
    item.and :doc_type, 0
    item.and :title_id, params[:parent]
    @item = item.find(params[:id])
  end

  def update
    @item = Gwqa::Doc.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def destroy
    @item = Gwqa::Doc.new.find(params[:id])
    _destroy @item
  end

end
