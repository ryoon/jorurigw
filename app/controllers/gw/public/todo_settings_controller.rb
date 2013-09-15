class Gw::Public::TodoSettingsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold

  end

  def reminder
    key = 'todos'
    @item = Gw::Model::Schedule.get_settings key
  end

  def edit_reminder
    key = 'todos'
    _params = params[:item]
    hu = nz(Gw::Model::UserProperty.get(key.singularize), {})
    default = Gw::NameValue.get_cache('yaml', nil, "gw_#{key}_settings_system_default")

    hu[key] = {} if hu[key].nil?
    hu_update = hu[key]
    hu_update['finish_todos_display']   = _params['finish_todos_display']
    hu_update['unfinish_todos_display_start'] = _params['unfinish_todos_display_start']
    hu_update['unfinish_todos_display_end'] = _params['unfinish_todos_display_end']

    options = {}
    ret = Gw::Model::UserProperty.save(key.singularize, hu, options)
    if ret == true
      flash_notice('設定編集処理', true)
       redirect_to "/gw/todo_settings"
    else
      respond_to do |format|
        format.html {
          hu_update['errors'] = ret
          hu_update.merge!(default){|k, self_val, other_val| self_val}
          @item = hu[key]
          render :action => "reminder"
        }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def schedule
    key = 'todos'
    @item = Gw::Model::Schedule.get_settings key
  end

  def edit_schedule
    key = 'todos'
    _params = params[:item]
    hu = nz(Gw::Model::UserProperty.get(key.singularize), {})
    default = Gw::NameValue.get_cache('yaml', nil, "gw_#{key}_settings_system_default")
    hu[key] = {} if hu[key].nil?
    hu_update = hu[key]
    hu_update['todos_display_schedule']   = _params['todos_display_schedule']

    options = {}
    ret = Gw::Model::UserProperty.save(key.singularize, hu, options)
    if ret == true
      flash_notice('設定編集処理', true)
       redirect_to "/gw/todo_settings"
    else
      respond_to do |format|
        format.html {
          hu_update['errors'] = ret
          hu_update.merge!(default){|k, self_val, other_val| self_val}
          @item = hu[key]
          render :action => "reminder"
        }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def admin_deletes
    key = 'todos'
    options = {}
    options[:class_id] = 3
    @item = Gw::Model::Schedule.get_settings key, options
  end

  def edit_admin_deletes
    key = 'todos'
    options = {}
    options[:class_id] = 3

    _params = params[:item]
    hu = nz(Gw::Model::UserProperty.get(key.singularize), {})
    default = Gw::NameValue.get_cache('yaml', nil, "gw_#{key}_settings_system_default")

    hu[key] = {} if hu[key].nil?
    hu_update = hu[key]
    hu_update['todos_admin_delete']   = _params['todos_admin_delete']

    ret = Gw::Model::UserProperty.save(key.singularize, hu, options)
    if ret == true
      flash_notice('ToDo削除設定処理', true)
       redirect_to "/gw/admin_settings"
    else
      respond_to do |format|
        format.html {
          hu_update['errors'] = ret
          hu_update.merge!(default){|k, self_val, other_val| self_val}
          @item = hu[key]
          render :action => "admin_deletes"
        }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end



end
